# 30 - Vertex AI Pipelines (KFP v2)

Author, compile, and launch a Vertex AI Pipeline that calls a text model, scores the result, and writes to GCS. This focuses on service accounts, staging buckets, and repeatable runs. Always check the latest Vertex AI Pipelines Python/REST docs for version changes.

## Guide

- Use KFP v2 (`google-cloud-aiplatform` + `kfp>=2`) and keep your pipeline root in a dedicated GCS bucket.
- Run pipelines with a dedicated service account that owns only what it needs (`aiplatform.user` + scoped storage).
- Version pipelines in source control and trigger runs via `gcloud ai pipelines run` or the Python SDK—avoid Console clicks.
- Parameterize model ids, temperature, and output bucket paths; never bake secrets into pipeline code.

## Challenge

1. Terraform:
   - Create a staging bucket for pipelines, a service account for runs, and IAM bindings (`aiplatform.user`, `storage.admin` on the bucket).
   - Enable Vertex AI, Cloud Storage, and Cloud Build APIs.
2. Code:
   - Write a pipeline with two components: (a) call a Vertex publisher model for summarization, (b) write the response to GCS with metadata.
   - Compile the pipeline JSON and trigger a run with parameters.
3. Evolve Terraform: add Workload Identity Federation for CI to submit runs, CMEK on the bucket, and log export of pipeline job history.

## Solution (reference)

- `app/pipeline.py`: KFP v2 pipeline with generate + store components.
- `app/requirements.txt`: Dependencies.
- `terraform/main.tf`: APIs, bucket, runner service account with IAM.
- `terraform/variables.tf`: Inputs for project/region/bucket prefix.
- `terraform/outputs.tf`: Useful resource ids.

### Run the reference

```bash
cd adventures/30_vertex_pipelines/terraform
terraform init
terraform apply \
  -var="project_id=$PROJECT_ID" \
  -var="region=us-central1" \
  -var="zone=us-central1-a" \
  -var="bucket_prefix=gcp-adventure-pipelines"

cd ../app
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python pipeline.py \
  --project "$PROJECT_ID" \
  --region "us-central1" \
  --staging-bucket "gs://${PROJECT_ID}-gcp-adventure-pipelines" \
  --prompt-file sample_prompt.txt
```

### Verify

- Pipeline run: in Vertex AI > Pipelines, locate `gcp-adventure-text-pipeline` and check component logs for errors.
- Artifacts: list bucket contents for the JSON output:
  ```bash
  gsutil ls "gs://${PROJECT_ID}-gcp-adventure-pipelines/runs/"
  ```
- IAM: ensure the runner SA is the job service account; remove broad roles from your user to force impersonation.

Evolve with Workload Identity Federation for CI submitters, CMEK on the bucket, and log export of pipeline job history per current Vertex AI/KFP docs.
