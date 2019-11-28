provider "google" {
    credentials = "${file(var.gcp-credentials)}"
    project     = var.gcp-project
    region      = var.gcp-region
}

/*
resource "random_id" "instance_id" {
    // In case you need to append to the VM name
    byte_length = 8
}
*/

resource "google_compute_instance" "gcp-ubuntu" {
    project       = var.gcp-project
    name          = "gcp-ubuntu-arc"
    machine_type  = "f1-micro"
    zone          = "${var.gcp-region}-a"

    boot_disk {
        initialize_params {
           image = "ubuntu-os-cloud/ubuntu-1804-lts"
        }
    }

    network_interface {
        network       = "${data.google_compute_network.default.self_link}"
        access_config {
                 // Include this section to give the VM an external ip address
        }
    }

    metadata = {
        ssh-keys = "${var.ssh-user}:${file(var.ssh-pub-key-file)}"
    }

     metadata_startup_script = "sudo apt-get update && sudo apt-get install -yq tree jq"
}

data "google_compute_network" "default" {
    name                    = "default"
}


// Output the external ip of the GCP instance
output "gcp_ssh" {
    value = "ssh ${var.ssh-user}@${google_compute_instance.gcp-ubuntu.network_interface.0.access_config.0.nat_ip}"
}