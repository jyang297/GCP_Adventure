output "instance_name" { value = google_compute_instance.vllm.name }
output "api_ip" { value = var.assign_public_ip ? google_compute_address.vllm_ip.address : "use_private" }
output "service_account" { value = var.service_account_email }
