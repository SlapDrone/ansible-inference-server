#!/usr/bin/env bash
# Launch vLLM OpenAI API server with GPU support using docker run

set -e  # Exit on error

# Load configuration from environment variables with defaults from group_vars/all.yml
VLLM_IMAGE=${VLLM_IMAGE:-"vllm/vllm-openai:latest"}
MODEL=${MODEL:-"Qwen/Qwen2.5-72B-Instruct-AWQ"}
KV_CACHE_DTYPE=${KV_CACHE_DTYPE:-"fp8"}
LOAD_FORMAT=${LOAD_FORMAT:-"auto"}
QUANTIZATION=${QUANTIZATION:-"awq"}
GPU_MEM_UTIL=${GPU_MEM_UTIL:-0.90}
MAX_MODEL_LEN=${MAX_MODEL_LEN:-32000}
HOST_PORT=${VLLM_PORT:-8000}
HF_CACHE_DIR=${HF_CACHE_DIR:-"/opt/models/.cache/huggingface"}

# Required environment variables
if [ -z "$HF_TOKEN" ]; then
  echo "ERROR: HF_TOKEN environment variable must be set for Hugging Face authentication"
  exit 1
fi

# Construct Docker command
CMD="docker run --gpus all -d --rm \
  --ipc=host \
  -p ${HOST_PORT}:8000 \
  -v ${HF_CACHE_DIR}:/root/.cache/huggingface \
  -e HUGGING_FACE_HUB_TOKEN=${HF_TOKEN} \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e VLLM_ATTENTION_BACKEND=FLASHINFER \
  ${VLLM_IMAGE} \
  --host 0.0.0.0 \
  --port 8000 \
  --model ${MODEL} \
  --kv-cache-dtype ${KV_CACHE_DTYPE} \
  --load-format ${LOAD_FORMAT} \
  --gpu-memory-utilization ${GPU_MEM_UTIL} \
  --max-model-len ${MAX_MODEL_LEN} \
  --use-v2-block-manager \
  --quantization ${QUANTIZATION} \
  --calculate-kv-scales"

echo "Starting vLLM container with command:"
echo "$CMD"

exec $CMD
