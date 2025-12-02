variable "project_id" {
  description = "Target GCP project"
  type        = string
}

variable "region" {
  description = "Default region"
  type        = string
}

variable "zone" {
  description = "Default zone"
  type        = string
}

variable "alert_email" {
  description = "Email for Monitoring notifications (must be verified)"
  type        = string
}

variable "bigquery_location" {
  description = "BigQuery dataset location (US/EU/regional)"
  type        = string
  default     = "US"
}

variable "kms_key_name" {
  description = "Optional CMEK key resource name for BigQuery"
  type        = string
  default     = ""
}
