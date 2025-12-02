# 10 - vLLM on Compute Engine

Run vLLM on a GPU VM, expose an OpenAI-compatible endpoint, and lock down access. Follow the Guide → Challenge → Solution. Verify GPU availability and driver instructions against the latest Compute Engine docs before applying.

## Guide

- Pick a region/zone with the GPU type you can get (e.g., `nvidia-tesla-t4` or `nvidia-l4`). Check quotas and enable Compute Engine API.
- Use a custom service account for the VM (least privilege: logging, storage read if pulling models from GCS/AR, Artifact Registry reader if using private images).
- Attach to the VPC from foundations and restrict ingress to HTTPS/SSH via firewall or load balancer.
- Use a startup script to install NVIDIA drivers, Python 3.10+, and `vllm` with the OpenAI server entrypoint.

## Challenge

1. Write Terraform to create a GPU VM on your `advnet-main` VPC:
   - Machine type sized to the GPU (e.g., `n1-standard-8` with T4) and boot disk 100GB.
   - Startup script that installs CUDA drivers, Python, and runs `python3 -m vllm.entrypoints.openai.api_server` with your chosen model.
   - Attach a static external IP only while testing; otherwise, place behind an HTTPS load balancer with IAP.
2. Deploy the sample FastAPI `server.py` and verify `/health` and `/v1/completions` endpoints.
3. Add logging sink to Cloud Logging; confirm tokens are never logged.
4. Evolve Terraform: add a `preemptible` toggle and a MIG template for horizontal scaling.

## Solution (reference)

### Files

- `app/server.py`: Minimal FastAPI wrapper around vLLM OpenAI-compatible API.
- `app/requirements.txt`: Dependencies.
- `app/startup.sh`: GPU driver + Python + service launch.
- `terraform/main.tf`: GPU VM, firewall, service account, and startup metadata.
- `terraform/variables.tf`: Inputs for project, regions, VPC, model.

### Run locally (GPU box)

```bash
cd adventures/10_vllm_compute_engine/app
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
MODEL=meta-llama/Llama-2-7b-chat-hf \  # pick a model you are licensed for
python server.py --model "$MODEL" --host 0.0.0.0 --port 8000
```

Then hit `http://localhost:8000/v1/completions` with an OpenAI-compatible request.

### Terraform apply (reference)

```bash
cd adventures/10_vllm_compute_engine/terraform
terraform init
terraform plan \
  -var="project_id=$PROJECT_ID" \
  -var="region=us-central1" \
  -var="zone=us-central1-a" \
  -var="network_name=advnet-main" \
  -var="subnet_name=adv-primary" \
  -var="model_id=meta-llama/Llama-2-7b-chat-hf" \
  -var="service_account_email=terraform-runner@${PROJECT_ID}.iam.gserviceaccount.com"
```

Update the GPU type/driver steps per the latest official docs. Once created, SSH through IAP or your restricted firewall; avoid leaving a public IP attached in real usage.
