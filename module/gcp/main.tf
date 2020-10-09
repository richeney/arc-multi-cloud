locals {
  ssh_private_key_file = trimsuffix(var.ssh_pub_key_file, ".pub")
}

resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "${var.hostname}-ssh-keys"
  value = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"

}

data "template_file" "gcp_cloud_init" {
  template = file("${path.root}/templates/cloud-init.tpl")

  vars = {
    hostname    = var.hostname
    myadminuser = var.ssh_user
    mysshkey    = file(var.ssh_pub_key_file)
  }
}

resource "local_file" "cloud_init_gcp" {
  sensitive_content    = data.template_file.gcp_cloud_init.rendered
  filename             = "${path.root}/playbooks/${var.hostname}-cloud-init"
  directory_permission = "0750"
  file_permission      = "0640"
}

data "template_file" "gcp_ansible" {
  template = file("${path.root}/templates/azure_arc.yml.tpl")

  vars = {
    tenant_id                = var.arc.tenant_id
    subscription_id          = var.arc.subscription_id
    service_principal_appid  = var.arc.service_principal_appid
    service_principal_secret = var.arc.service_principal_secret
    resource_group_name      = var.arc.resource_group_name
    location                 = var.arc.location
    cloud                    = "gcp"
    hostname                 = var.hostname
  }
}

resource "local_file" "gcp_ansible" {
  sensitive_content    = data.template_file.gcp_ansible.rendered
  filename             = "${path.root}/playbooks/${var.hostname}-playbook.yml"
  directory_permission = "0750"
  file_permission      = "0640"
}


resource "google_compute_instance" "gcp_ubuntu" {
  depends_on = [
    data.template_file.gcp_cloud_init,
    data.template_file.gcp_ansible,
  ]

  name         = var.hostname
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = data.google_compute_network.default.self_link
    access_config {
      // Include this section to give the VM an external ip address
    }
  }

  metadata = {
    user-data = data.template_file.gcp_cloud_init.rendered
  }

  // metadata_startup_script = "sudo apt-get update && sudo apt-get install -yq tree jq && sudo apt-get dist-upgrade -yq"

  provisioner "remote-exec" {
    inline = ["echo 'The ssh service is up and running...'"]

    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = var.ssh_user
      private_key = file(local.ssh_private_key_file)
    }
  }

  provisioner "local-exec" {
    // command = "ansible-playbook -i '${google_compute_instance.tfansible.network_interface.0.access_config.0.assigned_nat_ip},' --private-key ${var.private_key_path} data.template_file.ansible_aws.rendered"
    // Ansible inventory list needs the trailing comma
    command = "ansible-playbook -i '${self.network_interface.0.access_config.0.nat_ip},' --user=${var.ssh_user} --private-key ${local.ssh_private_key_file} ${path.root}/playbooks/${var.hostname}-playbook.yml --verbose"
  }
}

data "google_compute_network" "default" {
  name = "default"
}
