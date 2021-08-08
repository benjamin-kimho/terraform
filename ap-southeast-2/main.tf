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
  region  = "ap-southeast-2"
}

resource "aws_instance" "vpn_server" {
  ami           = "ami-07aa5ef6af56f8da2"
  instance_type = "c6g.medium"
  key_name      = "MPG"

  security_groups = ["Wireguard-VPN"]

  tags = {
    Name = "WireguardVpnServer"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("./MPG.pem")
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
