module "providers" {
  source = "../../../shared/terraform"
}

resource "google_artifact_registry_repository" "vllm" {
  provider      = google-beta
  location      = var.region
  repository_id = "vllm-vertex"
  description   = "Images for vLLM custom containers"
  format        = "DOCKER"
}

resource "google_storage_bucket" "models" {
  name          = "${var.project_id}-vllm-models"
  location      = var.region
  force_destroy = false
  uniform_bucket_level_access = true
}

resource "google_service_account" "vertex_sa" {
  account_id   = var.vertex_sa_name
  display_name = "Vertex vLLM runtime"
}

resource "google_project_iam_member" "artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.vertex_sa.email}"
}

resource "google_project_iam_member" "bucket_reader" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.vertex_sa.email}"
}

resource "google_vertex_ai_model" "vllm" {
  provider         = google-beta
  display_name     = "vllm-openai"
  project          = var.project_id
  region           = var.region
  container_spec {
    image_uri = var.image_uri
    prediction_route = "/predict"
    health_route      = "/ping"
    env = [
      "MODEL_ID=${var.model_id}"
    ]
  }
}

resource "google_vertex_ai_endpoint" "vllm" {
  provider     = google-beta
  display_name = "vllm-endpoint"
  project      = var.project_id
  region       = var.region
}

resource "google_vertex_ai_endpoint_deployed_model" "deploy" {
  provider    = google-beta
  endpoint    = google_vertex_ai_endpoint.vllm.id
  model       = google_vertex_ai_model.vllm.id
  display_name = "vllm-deployed"

  dedicated_resources {
    machine_spec {
      machine_type   = var.machine_type
      accelerator_type  = var.accelerator_type
      accelerator_count = 1
    }
    min_replica_count = var.min_replicas
    max_replica_count = var.max_replicas
  }

  traffic_split = { "0" = 100 }
  service_account = google_service_account.vertex_sa.email
}
