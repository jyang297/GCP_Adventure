output "runner_sa_email" { value = google_service_account.runner.email }
output "network" { value = google_compute_network.main.name }
output "subnets" { value = { for k, v in google_compute_subnetwork.regional : k => v.ip_cidr_range } }
output "state_bucket" { value = google_storage_bucket.tf_state.url }
