variable "project_id" { type = string }
variable "region" { type = string }
variable "model_id" { description = "Model id to load in container" type = string }
variable "image_uri" { description = "Container image uri in Artifact Registry" type = string }
variable "vertex_sa_name" { description = "Service account id (without domain)" type = string default = "vertex-vllm-sa" }
variable "machine_type" { description = "Compute machine type for deployment" type = string default = "n1-standard-8" }
variable "accelerator_type" { description = "GPU type (e.g., NVIDIA_TESLA_T4, NVIDIA_L4)" type = string default = "NVIDIA_TESLA_T4" }
variable "min_replicas" { type = number default = 1 }
variable "max_replicas" { type = number default = 1 }
