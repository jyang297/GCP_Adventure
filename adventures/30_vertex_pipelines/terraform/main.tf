module "providers" {
  source = "../../shared/terraform"
}

locals {
  bucket_name = "${var.project_id}-${var.bucket_prefix}"
}

resource "google_project_service" "apis" {
  for_each = toset([
    "aiplatform.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_storage_bucket" "pipeline_root" {
  name                        = local.bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  versioning { enabled = true }
  encryption {
    default_kms_key_name = var.kms_key_name != "" ? var.kms_key_name : null
  }
}

resource "google_service_account" "runner" {
  account_id   = "pipeline-runner"
  display_name = "Vertex Pipelines runner"
}

resource "google_project_iam_member" "runner_aiplatform" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_storage_bucket_iam_member" "runner_bucket_admin" {
  bucket = google_storage_bucket.pipeline_root.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.runner.email}"
}
