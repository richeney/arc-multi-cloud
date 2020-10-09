output "hostname" {
  value = var.hostname
}

output "ssh" {
  value       = "ssh ${var.ssh_user}@${aws_instance.aws_ubuntu.public_ip}"
  description = "SSH command to access the VM"
}

output "public_ip" {
  value = aws_instance.aws_ubuntu.public_ip
  description = "The public IP of the aws server"
}
