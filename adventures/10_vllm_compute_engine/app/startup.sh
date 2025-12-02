#!/usr/bin/env bash
set -euxo pipefail

MODEL_ID=${MODEL_ID:-"meta-llama/Llama-2-7b-chat-hf"}
LOG_FILE=/var/log/vllm-startup.log
exec > >(tee -a "$LOG_FILE") 2>&1

# Update packages and install basics.
apt-get update
apt-get install -y python3 python3-venv python3-pip build-essential git

# Install NVIDIA drivers using the public script (check latest from docs for your GPU).
if command -v nvidia-smi; then
  echo "GPU driver already present"
else
  curl -sS https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb
  dpkg -i /tmp/cuda-keyring.deb
  apt-get update
  apt-get install -y cuda-drivers
fi

# Python env for vLLM.
python3 -m venv /opt/vllm-venv
source /opt/vllm-venv/bin/activate
pip install --upgrade pip
pip install -r /opt/app/requirements.txt

# Launch server in background with basic nohup; replace with systemd for prod.
nohup python /opt/app/server.py --model "$MODEL_ID" --host 0.0.0.0 --port 8000 &
