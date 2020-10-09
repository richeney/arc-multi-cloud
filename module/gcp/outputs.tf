output "hostname" {
  value = var.hostname
}

output "ssh" {
  value       = "ssh ${var.ssh_user}@${google_compute_instance.gcp_ubuntu.network_interface.0.access_config.0.nat_ip}"
  description = "Command to SSH into the GCP VM"
}

output "public_ip" {
  value = google_compute_instance.gcp_ubuntu.network_interface.0.access_config.0.nat_ip
  description = "Command to SSH into the GCP VM"
}