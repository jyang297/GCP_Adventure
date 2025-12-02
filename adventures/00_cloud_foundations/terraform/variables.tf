variable "project_id" { description = "Target GCP project" type = string }
variable "region" { description = "Primary region" type = string }
variable "secondary_region" { description = "Secondary region" type = string }
variable "zone" { description = "Default zone" type = string }
variable "my_ip_cidr" { description = "Your public IP in CIDR, e.g., 203.0.113.4/32" type = string }
variable "billing_account" { description = "Billing account id (XXXXXX-XXXXXX-XXXXXX)" type = string }
variable "budget_pubsub_topic" { description = "Existing Pub/Sub topic for budget alerts" type = string }
