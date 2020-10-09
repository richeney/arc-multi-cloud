locals {
  ssh_private_key_file = trimsuffix(var.ssh_pub_key_file, ".pub")
}

data "template_file" "aws_cloud_init" {
  template = file("${path.root}/templates/cloud-init.tpl")

  vars = {
    hostname    = var.hostname
    myadminuser = var.ssh_user
    mysshkey    = file(var.ssh_pub_key_file)
  }
}

resource "local_file" "aws_cloud_init" {
  sensitive_content    = data.template_file.aws_cloud_init.rendered
  filename             = "${path.root}/playbooks/${var.hostname}-cloud-init"
  directory_permission = "0750"
  file_permission      = "0640"
}

data "template_file" "aws_ansible" {
  template = file("${path.root}/templates/azure_arc.yml.tpl")

  vars = {
    tenant_id                = var.arc.tenant_id
    subscription_id          = var.arc.subscription_id
    service_principal_appid  = var.arc.service_principal_appid
    service_principal_secret = var.arc.service_principal_secret
    resource_group_name      = var.arc.resource_group_name
    location                 = var.arc.location
    cloud                    = "aws"
    hostname                 = var.hostname
  }
}

resource "local_file" "aws_ansible" {
  sensitive_content    = data.template_file.aws_ansible.rendered
  filename             = "${path.root}/playbooks/${var.hostname}-playbook.yml"
  directory_permission = "0750"
  file_permission      = "0640"
}

data "aws_ami" "ubuntu-18_04" {
  most_recent = true
  owners      = ["099720109477"] //canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "ssh" {
  key_name   = "${var.hostname}-${var.ssh_user}"
  public_key = file(var.ssh_pub_key_file)
}

resource "aws_security_group" "allow_ssh" {
  name = "${var.hostname}-ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Uses user ubuntu by default.
// Leverage userdata to add the preferred username.

resource "aws_instance" "aws_ubuntu" {
  depends_on = [
    data.template_file.aws_cloud_init,
    data.template_file.aws_ansible,
  ]

  ami                    = data.aws_ami.ubuntu-18_04.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = true

  user_data = data.template_file.aws_cloud_init.rendered

  provisioner "remote-exec" {
    inline = ["echo 'The ssh service is up and running...'"]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = var.ssh_user
      private_key = file(local.ssh_private_key_file)
    }
  }

  provisioner "local-exec" {
    // command = "ansible-playbook -i '${google_compute_instance.tfansible.network_interface.0.access_config.0.assigned_nat_ip},' --private-key ${var.private_key_path} data.template_file.ansible_aws.rendered"
    // Ansible inventory list needs the trailing comma
    command = "ansible-playbook -i '${self.public_ip},' --user=${var.ssh_user} --private-key ${local.ssh_private_key_file} ${path.root}/playbooks/${var.hostname}-playbook.yml --verbose"
  }
}
