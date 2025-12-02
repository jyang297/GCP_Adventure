# 05 - IAM + Observability

Harden IAM and capture evidence with audit logs that feed BigQuery and alerting. Terraform-only—no console clicking. Cross-check IAM, Logging, and Monitoring provider fields with the latest Google Cloud docs (API names and schema evolve).

## Guide

- Aim for impersonation-first: authenticate as your user, then impersonate service accounts for Terraform and workloads (`GOOGLE_IMPERSONATE_SERVICE_ACCOUNT`). Confirm IAM scopes in the official docs as defaults change.
- Enable structured audit logs and export them to analytics (BigQuery). Prefer partitioned tables and expiration to control cost.
- Set notification channels and alert policies that fire on risky IAM events (e.g., `setIamPolicy`, `CreateServiceAccount`). Re-check Monitoring filter syntax from the latest docs.
- Keep least privilege: create scoped service accounts per workload and bind only the roles you need.
- Keep Terraform state remote once comfortable (GCS with versioning) and guard the bucket with IAM.

## Challenge

1. Terraform:
   - Create a BigQuery dataset for audit logs and a log sink that exports admin/data access logs with partitioned tables.
   - Create an email notification channel and an alert policy that triggers on IAM changes (filter on `setIamPolicy` or `CreateServiceAccount`).
   - Create a service account for observability automation (e.g., log parsers) with only `logging.viewer` and `bigquery.dataViewer`.
2. Code:
   - Produce a custom log entry that includes a structured field (`action=trailhead_test`) and verify it lands in BigQuery.
   - Query the exported table for that marker.
3. Terraform evolution: add CMEK for the dataset, a Pub/Sub sink for SIEM, and a VPC-SC perimeter around the project.

## Solution (reference)

- `terraform/main.tf`: API enablement, audit log sink to BigQuery (partitioned), alert policy on IAM changes, IAM bindings, automation service account.
- `terraform/variables.tf`: Inputs for project/region/zone/email.
- `terraform/outputs.tf`: Handy IDs and sink writer.
- `app/push_custom_metric.py`: Emits a structured log to exercise the sink and metric.

### Run the reference

```bash
cd adventures/05_iam_observability/terraform
terraform init
terraform plan \
  -var="project_id=$PROJECT_ID" \
  -var="region=us-central1" \
  -var="zone=us-central1-a" \
  -var="alert_email=you@example.com"
terraform apply

cd ../app
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python push_custom_metric.py --project "$PROJECT_ID" --region "us-central1"
```

### Verify

- BigQuery: look in dataset `audit_logs`, table `cloudaudit_googleapis_com_activity_*`. Example query:
  ```sql
  SELECT timestamp, protoPayload.methodName, jsonPayload
  FROM `${PROJECT_ID}.audit_logs.cloudaudit_googleapis_com_activity_*`
  WHERE jsonPayload.action = "trailhead_test"
  ORDER BY timestamp DESC
  LIMIT 10;
  ```
- Logging: `gcloud logging read 'jsonPayload.action="trailhead_test"' --limit 5 --project $PROJECT_ID`
- Alert channel: confirm email is verified in Monitoring. Trigger by running `gcloud iam service-accounts create temp-test --project $PROJECT_ID` and then deleting it.

Evolve by adding CMEK (dataset + sink), a Pub/Sub sink for SIEM, and private access per the current IAM/Logging docs.
