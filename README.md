# GCP Adventure

Hands-on learning path to grow from beginner to senior-level practitioner of Google Cloud Platform (with an AI/vLLM focus). Each adventure follows a Guide → Challenge → Solution flow and evolves Terraform infrastructure as code (IaC). Nothing here requires clicking around in the Console—stick to Terraform, `gcloud`, and code. Verify GPU types, API names, and quotas in the latest official Google Cloud docs as you progress.

> Reference the official Google Cloud docs as you work (APIs, quotas, GPU availability, Vertex AI, Terraform provider). This repo gives structure and working samples, but you should always confirm the latest details in the docs for your region and quotas.

## Structure

- `adventures/00_cloud_foundations`: Practitioner ramp-up, core IAM/networking, and Terraform basics.
- `adventures/05_iam_observability`: Audit logs, BigQuery sinks, monitoring alerts, and impersonation-first IAM.
- `adventures/10_vllm_compute_engine`: Stand up vLLM on Compute Engine GPUs, package a starter server, and secure access.
- `adventures/15_cloud_run_vertex_proxy`: Cloud Run gateway that fronts Vertex AI publisher models/endpoints with least-privilege IAM.
- `adventures/20_vertex_vllm`: Deploy vLLM as a custom container on Vertex AI endpoints with Artifact Registry + GCS.
- `adventures/30_vertex_pipelines`: Author and launch Vertex AI Pipelines with KFP v2 components and secured service accounts.
- `shared/terraform`: Reusable provider/backend snippets.

## How to use

1. Start in `adventures/00_cloud_foundations`. Complete the Guide, attempt the Challenge, then study the Solution.
2. Progress through the folders in order (00 → 05 → 10 → 15 → 20 → 30). Each one adds Terraform skills and AI depth.
3. Run the Terraform per adventure (fill in variables), deploy the provided code, and then evolve it per the Challenge prompts.
4. Keep notes on your decisions. Extend Terraform as you solve challenges (logging, autoscaling, CMEK, private access, WiF).
5. Validate with official docs before applying: API names, GPU availability, and IAM defaults change over time.

## Prereqs

- `gcloud` CLI authenticated (`gcloud auth application-default login`) and a GCP project with billing enabled.
- Terraform >= 1.6 with the `google` and `google-beta` providers.
- For GPU labs, confirm GPU availability/quotas in your region and enable Compute Engine + Vertex AI APIs.

## Quick nav

- Foundations: `adventures/00_cloud_foundations/README.md`
- vLLM on Compute Engine: `adventures/10_vllm_compute_engine/README.md`
- vLLM on Vertex AI: `adventures/20_vertex_vllm/README.md`
# GCP_Adventure
