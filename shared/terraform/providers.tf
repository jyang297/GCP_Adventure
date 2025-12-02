terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.33"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.33"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
