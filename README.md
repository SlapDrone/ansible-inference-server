# Ansible Playbook for LLM/AI Server Provisioning

This playbook provisions a Linux server (primarily tested on Ubuntu/Debian derivatives) with tools for running Large Language Models (LLMs) and Embedding models locally using Docker, Ollama, and Infinity. vLLM is run via its official Docker container.

**Features:**

*   Installs common prerequisites (`git`, `git-lfs`, `python3-pip`, etc.).
*   Installs Docker Engine & Docker Compose Plugin.
*   Installs NVIDIA Container Toolkit and configures Docker for GPU usage (**Optional but Recommended for GPU acceleration**). Assumes NVIDIA Drivers are **already installed** unless `install_nvidia_drivers` is explicitly set to `true`.
*   Installs Ollama (via official script and managed by its systemd service).
*   Downloads specified models from Hugging Face using Git LFS.
*   Pulls and runs the official `vllm/vllm-openai` Docker container, configured to serve a specified model.
*   Pulls and runs the Infinity Embedding Server Docker container, configured to serve a specified model.

**Prerequisites:**

1.  **Ansible:** Ensure Ansible is installed on your control machine. Version 2.10+ recommended. Needs `community.docker` collection (`ansible-galaxy collection install community.docker`).
2.  **Target Server:** A Linux server (Ubuntu 20.04/22.04 recommended).
3.  **NVIDIA Drivers (Highly Recommended):** For GPU acceleration (vLLM, Infinity, Ollama), ensure compatible NVIDIA drivers are **already installed** on the target server *before* running this playbook (unless you explicitly set `install_nvidia_drivers: true` and use Ubuntu).
4.  **SSH Access:** Passwordless SSH access (key-based) configured from your control machine to the target server for the user specified in the `inventory` file (`ansible_user`).
5.  **Sudo Access:** The `ansible_user` must have passwordless `sudo` privileges on the target server, or you need to provide the sudo password using the `--ask-become-pass` flag when running the playbook.
6.  **Resources:** Sufficient RAM, Disk Space (for models!), and GPU VRAM for the models you intend to run.
7.  **Internet Access:** Required on the target machine for downloading packages, images, and models.

**Configuration:**

1.  **`inventory`:** Edit this file to define your target server's IP address or hostname and the SSH user (`ansible_user`).
2.  **`group_vars/all.yml`:** This is the main configuration file.
    *   `install_nvidia_drivers`: Set to `false` (default) if drivers are pre-installed.
    *   `configure_nvidia_toolkit`: Set to `true` (default) to install the NVIDIA Container Toolkit and configure Docker for GPU access.
    *   `models_base_dir`: Set the parent directory path on the host for model storage.
    *   `models_to_download`: Modify the list with the Hugging Face `repo_id` for each model you want.
    *   `vllm_docker_image`: Specify the vLLM Docker image tag (e.g., `vllm/vllm-openai:latest` or a specific version).
    *   `vllm_active_model_repo_id`: Specify the `repo_id` of the model vLLM should serve. It **must** be present in `models_to_download`.
    *   `infinity_active_model_repo_id`: Specify the `repo_id` of the embedding model Infinity should serve. It **must** be present in `models_to_download`.
    *   Review and adjust ports (`vllm_port`, `infinity_port`), `infinity_image` tag, and optional vLLM container arguments (`vllm_tensor_parallel_size`, etc.) as needed.

**How to Run:**

1.  Navigate to the root directory of this project (`ansible_llm_setup/`).
2.  **(One-time) Install Docker collection:** `ansible-galaxy collection install community.docker`
3.  **(Recommended) Syntax Check:** `ansible-playbook -i inventory.py playbook.yml --syntax-check`
4.  **(Recommended) Dry Run:** `ansible-playbook -i inventory.py playbook.yml --check`
5.  **Set Environment Variable**:
    ```bash
    export HF_TOKEN="your_huggingface_token_here"
    ```
6.  **Execute Playbook:** `ansible-playbook -i inventory.py playbook.yml`
    *   If sudo requires a password: `--ask-become-pass`

**Accessing Services:**

After the playbook successfully completes:

*   **vLLM OpenAI API:** `http://<your_server_ip>:{{ vllm_port }}` (Default: `http://<your_server_ip>:8000`)
*   **Ollama API:** `http://<your_server_ip>:11434`
*   **Infinity Embedding API:** `http://<your_server_ip>:{{ infinity_port }}` (Default: `http://<your_server_ip>:7997`)

**Checking Services:**

*   **List running containers:** `docker ps` (Should show `vllm_openai_server` and `infinity_server`).
*   **Check vLLM logs:** `docker logs vllm_openai_server -f`
*   **Check Infinity logs:** `docker logs infinity_server -f`
*   **Check Ollama service:** `systemctl status ollama`
*   **Check Ollama logs:** `journalctl -u ollama -f`

**Notes:**

*   Model downloads can take a long time.
*   Ensure firewall rules allow access to the configured ports.
*   For production, consider pinning image versions, non-root users inside containers (if images support it), and enhanced monitoring.
*   The HF_TOKEN environment variable must be set when running the playbook to allow vLLM to download models
