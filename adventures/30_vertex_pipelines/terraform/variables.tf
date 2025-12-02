variable "project_id" {
  description = "Target project id"
  type        = string
}

variable "region" {
  description = "Primary region"
  type        = string
}

variable "zone" {
  description = "Default zone"
  type        = string
}

variable "bucket_prefix" {
  description = "Prefix for the pipeline bucket (appended to project id)"
  type        = string
  default     = "gcp-adventure-pipelines"
}

variable "kms_key_name" {
  description = "Optional CMEK key resource name for the bucket"
  type        = string
  default     = ""
}
