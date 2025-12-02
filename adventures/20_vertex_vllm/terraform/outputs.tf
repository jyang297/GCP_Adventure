output "endpoint_id" { value = google_vertex_ai_endpoint.vllm.id }
output "endpoint_name" { value = google_vertex_ai_endpoint.vllm.name }
output "service_account" { value = google_service_account.vertex_sa.email }
