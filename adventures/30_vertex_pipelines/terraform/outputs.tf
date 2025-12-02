output "pipeline_bucket" {
  description = "GCS bucket for pipeline root/artifacts"
  value       = google_storage_bucket.pipeline_root.url
}

output "pipeline_runner_sa" {
  description = "Service account that submits pipeline runs"
  value       = google_service_account.runner.email
}
