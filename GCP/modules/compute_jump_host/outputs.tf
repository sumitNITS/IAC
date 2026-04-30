output "instance_id" {
  description = "Compute Engine instance ID for the jump host"
  value       = google_compute_instance.jump_host.id
}

output "instance_name" {
  description = "Name of the jump host VM"
  value       = google_compute_instance.jump_host.name
}

output "service_account_email" {
  description = "Email of the jump host service account"
  value       = google_service_account.jump_host.email
}

output "iap_ssh_command" {
  description = "Command to SSH into the jump host via IAP"
  value       = "gcloud compute ssh ${google_compute_instance.jump_host.name} --zone=${google_compute_instance.jump_host.zone} --tunnel-through-iap"
}
