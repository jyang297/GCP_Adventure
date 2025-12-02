module "providers" {
  source = "../../shared/terraform"
}

locals {
  repo_id = "vertex-proxy"
}

resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "aiplatform.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = local.repo_id
  format        = "DOCKER"
  description   = "Images for the Vertex proxy Cloud Run service"
}

resource "google_service_account" "proxy" {
  account_id   = "vertex-proxy"
  display_name = "Cloud Run Vertex proxy"
}

resource "google_project_iam_member" "proxy_aiplatform" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.proxy.email}"
}

resource "google_cloud_run_service" "proxy" {
  name     = "vertex-proxy"
  project  = var.project_id
  location = var.region

  template {
    metadata {
      annotations = {
        "run.googleapis.com/ingress" = var.ingress_setting
      }
    }
    spec {
      service_account_name = google_service_account.proxy.email
      containers {
        image = var.image_uri
        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "LOCATION"
          value = var.region
        }
        env {
          name  = "MODEL_ID"
          value = var.model_id
        }
        env {
          name  = "ENDPOINT_ID"
          value = var.endpoint_id
        }
        resources {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "invokers" {
  count    = var.allow_unauthenticated ? 1 : 0
  project  = google_cloud_run_service.proxy.project
  location = google_cloud_run_service.proxy.location
  service  = google_cloud_run_service.proxy.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "invoker_members" {
  for_each = toset(var.invoker_members)
  project  = google_cloud_run_service.proxy.project
  location = google_cloud_run_service.proxy.location
  service  = google_cloud_run_service.proxy.name
  role     = "roles/run.invoker"
  member   = each.value
}
