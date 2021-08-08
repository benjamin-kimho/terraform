terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-1"
}

resource "aws_instance" "vpn_server" {
  ami           = "ami-0c58a45b4cecce02c"
  instance_type = "c6g.medium"
  key_name      = "VPN"

  security_groups = ["vpn"]

  tags = {
    Name = "WireguardVpnServer"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("./VPN.pem")
  }

  provisioner "file" {
    source      = "../scripts/setup_wireguard.sh"
    destination = "~/setup_wireguard.sh"
  }


  provisioner "file" {
    source      = "../scripts/wireguard_create_peer.sh"
    destination = "~/wireguard_create_peer.sh"
  }

  provisioner "remote-exec" {
    inline = ["chmod +x ~/setup_wireguard.sh ~/wireguard_create_peer.sh"]
  }
}

output "public_ip" {
  value = aws_instance.vpn_server.public_ip
}
