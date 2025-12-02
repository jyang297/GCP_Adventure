# 20 - vLLM on Vertex AI (Custom Container)

Deploy vLLM as a custom prediction container to Vertex AI endpoints. This adventure uses Artifact Registry for the image and Cloud Storage for optional model weights. Always verify the latest Vertex AI custom container and GPU compatibility docs before applying.

## Guide

- Build a minimal image with vLLM and a FastAPI prediction server implementing Vertex AI's HTTP contract (`/ping` for health, `/predict` for inference).
- Push to an Artifact Registry repo in the same region as your endpoint.
- Create a Vertex Model resource that references the image, then deploy to an Endpoint with a GPU-backed machine type (e.g., `n1-standard-8` + T4 or `g2-standard-12` + L4, subject to availability).
- Prefer private service connect + VPC-SC for real workloads; this lab uses public endpoint with restricted access tokens.

## Challenge

1. Build and push the provided Dockerfile to Artifact Registry.
2. Use Terraform to create:
   - Artifact Registry repo (`vllm-vertex`),
   - GCS bucket for model artifacts (optional),
   - Vertex `Model` + `Endpoint` + deployment on GPU.
3. Call the endpoint with the OpenAI-like payload and confirm response.
4. Evolve Terraform to add autoscaling and dedicated service accounts for model/endpoint.

## Solution (reference)

### Files

- `app/Dockerfile`: Builds a vLLM-based image with a FastAPI server.
- `app/main.py`: Implements `/ping` and `/predict` for Vertex.
- `app/requirements.txt`: Python deps.
- `terraform/main.tf`: Artifact Registry, GCS bucket, Vertex model + endpoint + deployment.
- `terraform/variables.tf`: Inputs.

### Build & push

```bash
cd adventures/20_vertex_vllm/app
PROJECT_ID=$PROJECT_ID
REGION=us-central1
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/vllm-vertex/vllm-server:latest"

gcloud builds submit --tag "$IMAGE" .
```

### Deploy with Terraform

```bash
cd adventures/20_vertex_vllm/terraform
terraform init
terraform plan -var="project_id=$PROJECT_ID" -var="region=us-central1" -var="model_id=meta-llama/Llama-2-7b-chat-hf" \
  -var="image_uri=${REGION}-docker.pkg.dev/${PROJECT_ID}/vllm-vertex/vllm-server:latest"
```

After apply, use `gcloud ai endpoints predict` with your input. Update machine types and accelerators per the current Vertex AI GPU availability docs.
