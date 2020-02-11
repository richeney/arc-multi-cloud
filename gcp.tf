provider "google" {
    version     = "~> 3.4"
    credentials = file(var.gcp_credentials)
    project     = var.gcp_project
    region      = var.gcp_region
}

/*
resource "random_id" "instance_id" {
    // In case you need to append to the VM name
    byte_length = 8
}
*/

resource "google_compute_project_metadata_item" "ssh-keys" {
    project = var.gcp_project
    key     = "ssh-keys"
    value   = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"

}

data "template_file" "gcp_cloud_init" {
    template = file("cloud-init.tpl")

    vars = {
        hostname    = var.gcp_hostname
        myadminuser = var.ssh_user
        mysshkey    = file(var.ssh_pub_key_file)
    }
}

resource "local_file" "cloud_init_gcp" {
    sensitive_content       = data.template_file.gcp_cloud_init.rendered
    filename                = "${path.module}/playbooks/gcp-cloud-init"
    directory_permission    = "0750"
    file_permission         = "0640"
}

data "template_file" "gcp_ansible" {
    depends_on  = [
      azuread_service_principal_password.arc,
      ]

    template = file("azure_arc.yml.tpl")

    vars = {
        tenant_id                   = data.azurerm_subscription.arc.tenant_id
        subscription_id             = data.azurerm_subscription.arc.subscription_id
        service_principal_appid        = azuread_service_principal.arc.application_id
        service_principal_secret    = random_password.arc.result
        resource_group              = azurerm_resource_group.arc.name
        location                    = var.location
        cloud                       = "gcp"
        hostname                    = var.aws_hostname
    }
}

resource "local_file" "gcp_ansible" {
    sensitive_content       = data.template_file.gcp_ansible.rendered
    filename                = "${path.module}/playbooks/gcp-ansible-playbook.yml"
    directory_permission    = "0750"
    file_permission         = "0640"
}


resource "google_compute_instance" "gcp_ubuntu" {
    depends_on = [
      data.template_file.gcp_cloud_init,
      data.template_file.gcp_ansible,
    ]

    project       = var.gcp_project
    name          = "gcp-ubuntu-arc"
    machine_type  = "f1-micro"
    zone          = "${var.gcp_region}-a"

    boot_disk {
        initialize_params {
           image = "ubuntu-os-cloud/ubuntu-1804-lts"
        }
    }

    network_interface {
        network       = data.google_compute_network.default.self_link
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
        command = "ansible-playbook -i '${self.network_interface.0.access_config.0.nat_ip},' --user=${var.ssh_user} --private-key ${local.ssh_private_key_file} ${path.module}/playbooks/gcp-ansible-playbook.yml --verbose"
    }
}

data "google_compute_network" "default" {
    name = "default"
}


// Output the external ip of the GCP instance
output "gcp_ssh" {
    value = "ssh ${var.ssh_user}@${google_compute_instance.gcp_ubuntu.network_interface.0.access_config.0.nat_ip}"
}