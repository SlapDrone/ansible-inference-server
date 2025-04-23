#!/usr/bin/env bash
set -euo pipefail

### 1) — EDIT THESE VARIABLES AS NEEDED — ###
INSTALL_NVIDIA_DRIVERS=false
CONFIGURE_NVIDIA_TOOLKIT=true

MODELS_BASE_DIR=/opt/models
MODELS=(
  "mistralai/Mistral-7B-Instruct-v0.1"
  "sentence-transformers/all-MiniLM-L6-v2"
)

VLLM_IMAGE="vllm/vllm-openai:latest"
VLLM_PORT=8000
VLLM_REPO_ID="mistralai/Mistral-7B-Instruct-v0.1"

INFINITY_IMAGE="michaelfeil/infinity:latest"
INFINITY_PORT=7997
INFINITY_REPO_ID="sentence-transformers/all-MiniLM-L6-v2"
###########################################

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root or via sudo." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

### A) COMMON TASKS ###
apt-get update
apt-get install -y \
  python3-pip python3-venv git git-lfs wget curl \
  ca-certificates gnupg lsb-release

git lfs install --system

### B) DOCKER INSTALLATION ###
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
   https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

# add current SSH user (if any) to docker group
if [ -n "${SUDO_USER-}" ]; then
  usermod -aG docker "$SUDO_USER"
else
  usermod -aG docker "$(logname)"
fi

### C) NVIDIA DRIVER + TOOLKIT ###
#  C.1) optional driver install
if $INSTALL_NVIDIA_DRIVERS; then
  if lspci | grep -iq nvidia; then
    ubuntu-drivers autoinstall
  fi
fi

#  C.2) container toolkit
if $CONFIGURE_NVIDIA_TOOLKIT; then
  apt-get install -y curl
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  curl -sL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' \
    > /etc/apt/sources.list.d/nvidia-container-toolkit.list

  apt-get update
  apt-get install -y nvidia-container-toolkit

  # configure default runtime
  cat > /etc/docker/daemon.json <<EOF
{
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "default-runtime": "nvidia"
}
EOF

  systemctl restart docker
fi

### D) MODEL DOWNLOAD ###
mkdir -p "${MODELS_BASE_DIR}"
for repo in "${MODELS[@]}"; do
  name=${repo##*/}
  dest="${MODELS_BASE_DIR}/${name}"
  if [ -d "$dest/.git" ]; then
    echo "Updating model ${repo}..."
    git -C "$dest" pull --ff-only
  else
    echo "Cloning model ${repo}..."
    git clone "https://huggingface.co/${repo}" "$dest"
  fi
done

### E) INSTALL & START OLLAMA ###
if ! command -v ollama &>/dev/null; then
  curl -fsSL https://ollama.com/install.sh | sh
fi
if [ -f /etc/systemd/system/ollama.service ]; then
  systemctl enable --now ollama
fi

### F) RUN INFINITY SERVER ###
iname=all-MiniLM-L6-v2
imh="${MODELS_BASE_DIR}/${INFINITY_REPO_ID##*/}"
imc="/models/${INFINITY_REPO_ID##*/}"
mkdir -p "$imh"

docker pull "$INFINITY_IMAGE"
docker rm -f infinity_server 2>/dev/null || true
docker run -d \
  --name infinity_server \
  --restart unless-stopped \
  -p "${INFINITY_PORT}:7997" \
  -v "${imh}:${imc}:ro" \
  ${CONFIGURE_NVIDIA_TOOLKIT:+--gpus all} \
  "$INFINITY_IMAGE" \
    --model-name-or-path "$imc" --port 7997 --host 0.0.0.0

### G) RUN vLLM SERVER ###
vname=${VLLM_REPO_ID##*/}
vmh="${MODELS_BASE_DIR}/${vname}"
vmc="/models/${vname}"
mkdir -p "$vmh"

docker pull "$VLLM_IMAGE"
docker rm -f vllm_openai_server 2>/dev/null || true
docker run -d \
  --name vllm_openai_server \
  --restart unless-stopped \
  -p "${VLLM_PORT}:8000" \
  -v "${vmh}:${vmc}:ro" \
  ${CONFIGURE_NVIDIA_TOOLKIT:+--gpus all} \
  "$VLLM_IMAGE" \
    --host 0.0.0.0 --port 8000 \
    --model "$vmc" \
    --dtype auto \
    --device $([ "$CONFIGURE_NVIDIA_TOOLKIT" = true ] && echo cuda || echo cpu)

echo "✅ Setup complete.  Services listening on ports ${VLLM_PORT} (vLLM) and ${INFINITY_PORT} (Infinity)."
