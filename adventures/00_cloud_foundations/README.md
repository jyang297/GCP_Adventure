# 00 - Cloud Foundations (Practitioner)

Guided ramp into GCP basics with Terraform-first mindset. Use this to set up project scaffolding, IAM, networking, and logging that later adventures reuse.

## Guide

- Read: GCP project structure, billing, IAM (principals, roles, service accounts), VPC basics (subnets, firewall rules), and resource naming conventions.
- Set up Terraform locally with the Google provider. Use a remote backend (e.g., GCS) for state once comfortable; start local for learning.
- Enable required APIs up front (Compute Engine, Cloud Logging, Artifact Registry, Vertex AI). Confirm via `gcloud services list --available` if quotas/docs changed.
- Create a least-privilege service account for Terraform with roles like `roles/editor` (learning) or granular (prod), plus `roles/iam.serviceAccountTokenCreator` if impersonating.
- Establish a shared VPC with private subnets and ingress rules that restrict SSH to your IP.

## Challenge

1. Write Terraform to create:
   - A custom network `advnet-main` with two subnets (one per region of your choice) and a restricted firewall (ingress SSH from your IP, egress open).
   - A `terraform-runner` service account with a custom role that allows compute/network/admin-lite actions but not billing/project delete.
   - API enablement for `compute.googleapis.com`, `aiplatform.googleapis.com`, `artifactregistry.googleapis.com`, `logging.googleapis.com`.
2. Add a budget alert (Pub/Sub or email) to avoid surprises.
3. Store Terraform state in a GCS bucket with versioning.
4. Document how to impersonate the runner SA in your local `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` flow.

## Solution (reference)

The Terraform below is intentionally explicit so you can copy pieces into later adventures. Start in `terraform/` and run `terraform init && terraform plan` after setting variables.

### Files

- `terraform/main.tf`: Network, firewall, service account, API enablement, budget, state bucket.
- `terraform/variables.tf`: Inputs for project/region/ip.
- `terraform/outputs.tf`: Useful IDs to reuse later.

### Terraform walkthrough

```hcl
# terraform/main.tf
module "providers" {
  source = "../../shared/terraform"
}

locals {
  sa_name = "terraform-runner"
}

resource "google_project_service" "apis" {
  for_each           = toset([
    "compute.googleapis.com",
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "runner" {
  account_id   = local.sa_name
  display_name = "Terraform Runner"
}

resource "google_project_iam_custom_role" "runner_role" {
  role_id     = "terraformRunnerRole"
  title       = "Terraform Runner"
  description = "Scoped permissions for Terraform labs"
  permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.networks.create",
    "compute.networks.updatePolicy",
    "compute.subnetworks.create",
    "compute.subnetworks.use",
    "compute.firewalls.create",
    "compute.firewalls.update",
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.get",
    "resourcemanager.projects.get",
    "storage.buckets.create",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.get",
    "logging.logEntries.create",
  ]
}

resource "google_project_iam_member" "runner_binding" {
  project = var.project_id
  role    = google_project_iam_custom_role.runner_role.name
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_storage_bucket" "tf_state" {
  name          = "${var.project_id}-tf-state"
  location      = var.region
  force_destroy = false
  versioning { enabled = true }
}

resource "google_compute_network" "main" {
  name                    = "advnet-main"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "regional" {
  for_each               = {
    primary = { region = var.region, cidr = "10.10.0.0/20" }
    secondary = { region = var.secondary_region, cidr = "10.20.0.0/20" }
  }
  name          = "adv-${each.key}"
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.main.id
  private_ip_google_access = true
}

resource "google_compute_firewall" "ssh_restrict" {
  name    = "adv-allow-ssh"
  network = google_compute_network.main.name

  allow { protocol = "tcp" ports = ["22"] }
  source_ranges = [var.my_ip_cidr]
  direction     = "INGRESS"
}

resource "google_billing_budget" "monthly" {
  billing_account = var.billing_account
  display_name    = "Adventure Budget"

  amount { specified_amount { currency_code = "USD" units = 50 } }

  threshold_rules { threshold_percent = 0.5 }
  threshold_rules { threshold_percent = 0.8 }
  threshold_rules { threshold_percent = 1.0 }

  all_updates_rule {
    pubsub_topic        = var.budget_pubsub_topic
    schema_version      = "1.0"
    monitoring_notification_channels = []
    disable_default_iam_recipients   = false
  }
}
```

```hcl
# terraform/variables.tf
variable "project_id" { description = "Target GCP project" type = string }
variable "region" { description = "Primary region" type = string }
variable "secondary_region" { description = "Secondary region" type = string }
variable "zone" { description = "Default zone" type = string }
variable "my_ip_cidr" { description = "Your public IP in CIDR, e.g., 203.0.113.4/32" type = string }
variable "billing_account" { description = "Billing account id (XXXXXX-XXXXXX-XXXXXX)" type = string }
variable "budget_pubsub_topic" { description = "Existing Pub/Sub topic for budget alerts" type = string }
```

```hcl
# terraform/outputs.tf
output "runner_sa_email" { value = google_service_account.runner.email }
output "network" { value = google_compute_network.main.name }
output "subnets" { value = { for k, v in google_compute_subnetwork.regional : k => v.ip_cidr_range } }
output "state_bucket" { value = google_storage_bucket.tf_state.url }
```

### Run

```bash
cd adventures/00_cloud_foundations/terraform
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="terraform-runner@${PROJECT_ID}.iam.gserviceaccount.com"
terraform init
terraform plan -var="project_id=$PROJECT_ID" -var="region=us-central1" -var="secondary_region=us-east1" \
  -var="zone=us-central1-a" -var="my_ip_cidr=$(curl -s ifconfig.me)/32" \
  -var="billing_account=XXXXXX-XXXXXX-XXXXXX" -var="budget_pubsub_topic=projects/${PROJECT_ID}/topics/budget-topic"
```

If impersonation fails, ensure your user has `roles/iam.serviceAccountTokenCreator` on the runner SA. Re-run plan/apply only after validating API names/regions against the latest docs.
