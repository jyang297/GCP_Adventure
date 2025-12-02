variable "project_id" {
  description = "Target project id"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
}

variable "zone" {
  description = "Default zone (passed to shared provider)"
  type        = string
}

variable "image_uri" {
  description = "Container image URI pushed to Artifact Registry"
  type        = string
}

variable "model_id" {
  description = "Vertex publisher model id (e.g., text-bison@001)"
  type        = string
  default     = "text-bison@001"
}

variable "endpoint_id" {
  description = "Optional Vertex Endpoint id (UUID) to call instead of publisher model"
  type        = string
  default     = ""
}

variable "allow_unauthenticated" {
  description = "Grant public invocation if true"
  type        = bool
  default     = false
}

variable "invoker_members" {
  description = "Additional IAM members (e.g., user:you@example.com) who can invoke"
  type        = list(string)
  default     = []
}

variable "ingress_setting" {
  description = "Cloud Run ingress: all / internal-and-cloud-load-balancing / internal"
  type        = string
  default     = "all"
}
