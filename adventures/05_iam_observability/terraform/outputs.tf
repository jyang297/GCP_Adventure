output "automation_sa_email" {
  description = "Service account for observability automation"
  value       = google_service_account.automation.email
}

output "audit_dataset" {
  description = "Audit log dataset id"
  value       = google_bigquery_dataset.audit_logs.id
}

output "sink_writer_identity" {
  description = "Logging sink writer identity bound to BigQuery"
  value       = google_logging_project_sink.audit_to_bq.writer_identity
}

output "iam_alert_policy" {
  description = "Alert policy resource id"
  value       = google_monitoring_alert_policy.iam_changes.name
}
