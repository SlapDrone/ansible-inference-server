#!/usr/bin/env bash
set -euo pipefail

# 1. Pull the GGUF into the shared HF cache (downloads once, then re-uses)
python3 - <<'PY'
import os, shutil, pathlib
from huggingface_hub import hf_hub_download

repo  = os.environ["GGUF_REPO"]
fname = os.environ["GGUF_FILE"]
dst   = pathlib.Path("/models") / fname

if not dst.exists():
    print(f"[prefetch] downloading {repo}/{fname}")
    src = hf_hub_download(repo_id=repo, filename=fname)  # obeys HF cache
    shutil.copy(src, dst)
    print("[prefetch] done")
else:
    print("[prefetch] GGUF already present, skipping download")
PY

# 2. Hand off to the real vLLM entrypoint
exec vllm serve "$@"
