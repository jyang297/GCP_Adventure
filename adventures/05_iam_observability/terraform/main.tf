module "providers" {
  source = "../../shared/terraform"
}

locals {
  sink_name    = "audit-to-bq"
  dataset_id   = "audit_logs"
  alert_policy = "iam-policy-changes"
}

resource "google_project_service" "apis" {
  for_each = toset([
    "logging.googleapis.com",
    "bigquery.googleapis.com",
    "monitoring.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "automation" {
  account_id   = "obs-automation"
  display_name = "Observability automation"
}

resource "google_project_iam_member" "automation_logging" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.automation.email}"
}

resource "google_project_iam_member" "automation_bigquery" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.automation.email}"
}

resource "google_bigquery_dataset" "audit_logs" {
  dataset_id                 = local.dataset_id
  location                   = var.bigquery_location
  delete_contents_on_destroy = false
  default_encryption_configuration {
    kms_key_name = var.kms_key_name != "" ? var.kms_key_name : null
  }
}

resource "google_logging_project_sink" "audit_to_bq" {
  name                   = local.sink_name
  destination            = "bigquery.googleapis.com/${google_bigquery_dataset.audit_logs.id}"
  filter                 = "logName:(\"cloudaudit.googleapis.com%2Factivity\" OR \"cloudaudit.googleapis.com%2Fdata_access\")"
  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_bigquery_dataset_iam_member" "sink_writer" {
  dataset_id = google_bigquery_dataset.audit_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.audit_to_bq.writer_identity
}

resource "google_logging_metric" "iam_policy_change" {
  name   = "iam-policy-change-count"
  filter = "protoPayload.methodName=~\"(?i)setiampolicy|CreateServiceAccount\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    display_name = "IAM policy changes"
  }
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "IAM Alerts Email"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "iam_changes" {
  display_name = "IAM policy changes"
  combiner     = "OR"

  conditions {
    display_name = "IAM change spike"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.iam_policy_change.name}\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
  documentation {
    content   = "Investigate unexpected IAM changes. Start with Cloud Audit Logs in BigQuery partition for the alert minute."
    mime_type = "text/markdown"
  }
  user_labels = { play = "gcp-adventure" }
}
