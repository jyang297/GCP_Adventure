variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "network_name" { type = string }
variable "subnet_name" { type = string }
variable "service_account_email" { type = string }
variable "model_id" { description = "Model id for vLLM" type = string }
variable "api_ingress_cidr" { description = "CIDR allowed to hit port 8000" type = string }
variable "ssh_ingress_cidr" { description = "CIDR allowed to SSH" type = string }
variable "machine_type" { description = "Compute machine type" type = string default = "n1-standard-8" }
variable "gpu_type" { description = "GPU type (e.g., nvidia-tesla-t4)" type = string default = "nvidia-tesla-t4" }
variable "boot_image" { description = "Boot image" type = string default = "ubuntu-os-cloud/ubuntu-2204-lts" }
variable "assign_public_ip" { description = "Attach public IP for testing" type = bool default = true }
variable "preemptible" { description = "Use preemptible VM" type = bool default = false }
variable "app_bucket" { description = "GCS bucket storing packaged app" type = string }
variable "app_object" { description = "Tar.gz object containing server.py and requirements.txt" type = string }
variable "requirements_path" { description = "Path to requirements file within extracted archive" type = string default = "app/requirements.txt" }
