output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_service.proxy.status[0].url
}

output "proxy_service_account" {
  description = "Service account used by Cloud Run"
  value       = google_service_account.proxy.email
}

output "artifact_registry_repo" {
  description = "Artifact Registry repo id"
  value       = google_artifact_registry_repository.repo.id
}
