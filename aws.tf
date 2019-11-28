provider "aws" {
    region                  = "eu-west-2"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "terraform"
}

data "template_file" "cloud-init" {
    template = "${file("aws.cloud-init.tpl")}"

    vars = {
        myadminuser = var.ssh-user
        mysshkey    = "${file(var.ssh-pub-key-file)}"
    }
}

data "aws_ami" "ubuntu-18_04" {
  most_recent = true
  owners = ["099720109477"] //canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "ssh" {
    key_name   = var.ssh-user
    public_key = "${file(var.ssh-pub-key-file)}"
}

resource "aws_security_group" "allow-ssh" {
    name = "allow-ssh-access"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

// Uses user ubuntu by default.
// Leverage userdata to add the preferred username.

resource "aws_instance" "aws-ubuntu" {
    ami           = "${data.aws_ami.ubuntu-18_04.id}"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.allow-ssh.id ]

    key_name = aws_key_pair.ssh.key_name
    associate_public_ip_address = true

    user_data = "${data.template_file.cloud-init.rendered}"

    tags = {
        Name        = "aws-ubuntu"
        managedBy   = "AzureArc"
    }
}

output "aws_ssh" {
    value       = "ssh ${var.ssh-user}@${aws_instance.aws-ubuntu.public_ip}"
    description = "The public IP of the web server"
}