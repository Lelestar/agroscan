#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_PACKAGES="$ROOT_DIR/.venv/lib/python3.11/site-packages"
NVIDIA_DIR="$SITE_PACKAGES/nvidia"

export LD_LIBRARY_PATH="$NVIDIA_DIR/cudnn/lib:$NVIDIA_DIR/cublas/lib:$NVIDIA_DIR/cuda_runtime/lib:$NVIDIA_DIR/cuda_nvrtc/lib:$NVIDIA_DIR/cufft/lib:$NVIDIA_DIR/curand/lib:$NVIDIA_DIR/cusolver/lib:$NVIDIA_DIR/cusparse/lib:$NVIDIA_DIR/nccl/lib:$NVIDIA_DIR/nvjitlink/lib:${LD_LIBRARY_PATH:-}"
export TF_CPP_MIN_LOG_LEVEL="${TF_CPP_MIN_LOG_LEVEL:-1}"

exec "$@"
