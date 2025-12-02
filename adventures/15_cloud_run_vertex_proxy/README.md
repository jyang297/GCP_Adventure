# 15 - Cloud Run Vertex Proxy

Deploy a small Cloud Run gateway that fronts Vertex AI publisher models or an existing Endpoint. Keep IAM tight and automate infra with Terraform. Confirm current model IDs and Vertex auth guidance in the official docs before deploying.

## Guide

- Build a tiny FastAPI container that accepts OpenAI-like payloads and forwards to Vertex AI (`publisher model` or `Endpoint` if you already deployed one).
- Use Artifact Registry for the image and a dedicated service account for the Cloud Run service with only `roles/aiplatform.user`.
- Default to private invocation: disable unauthenticated access and grant `roles/run.invoker` only to your principals.
- Keep config in env vars (`PROJECT_ID`, `LOCATION`, `MODEL_ID`, optional `ENDPOINT_ID`). Avoid hardcoding secrets or models.

## Challenge

1. Build and push the provided Dockerfile to Artifact Registry.
2. Terraform:
   - Create an Artifact Registry repo (`vertex-proxy`), a Cloud Run service using your image, and a service account with `aiplatform.user`.
   - Wire env vars for project/region/model IDs and disable unauthenticated access by default.
   - Add optional `ingress` restriction to internal + Cloud Load Balancing only.
3. Call `POST /predict` with a prompt and verify the Vertex response.
4. Evolve Terraform: add Cloud Armor on the HTTPS LB, request logging sinks, and workload identity federation for CI to deploy the image.

## Solution (reference)

- `app/Dockerfile`: Small Python base image with FastAPI + Vertex client.
- `app/main.py`: Receives an OpenAI-style payload and forwards to Vertex publisher model or endpoint.
- `app/requirements.txt`: Dependencies.
- `terraform/main.tf`: Repo, service account, IAM bindings, Cloud Run service.
- `terraform/variables.tf`: Inputs for project/region/image/model.
- `terraform/outputs.tf`: Service URL and SA email.

### Build & deploy (reference)

```bash
cd adventures/15_cloud_run_vertex_proxy/app
PROJECT_ID=$PROJECT_ID
REGION=us-central1
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/vertex-proxy/proxy:latest"
gcloud builds submit --tag "$IMAGE" .

cd ../terraform
terraform init
terraform apply \
  -var="project_id=$PROJECT_ID" \
  -var="region=$REGION" \
  -var="zone=${REGION}-a" \
  -var="image_uri=$IMAGE" \
  -var="model_id=text-bison@001" \
  -var="allow_unauthenticated=false"
```

### Verify

- IAM: grant your principal `roles/run.invoker` if `allow_unauthenticated=false`:
  ```bash
  gcloud run services add-iam-policy-binding vertex-proxy \
    --region $REGION --project $PROJECT_ID \
    --member="user:you@example.com" --role="roles/run.invoker"
  ```
- Call the service:
  ```bash
  URL=$(terraform output -raw service_url)
  curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
       -H "Content-Type: application/json" \
       -X POST "$URL/predict" \
       -d '{"prompt":"Say hello from Vertex via Cloud Run"}'
  ```
- Switch to a custom Endpoint: set `endpoint_id` in Terraform/vars and leave `model_id` blank; redeploy.

Review the latest Vertex AI prediction docs for current publisher model names, auth guidance, and quotas.
