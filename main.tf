terraform {
  required_providers {
    aws = {
      source      = "hashicorp/aws"
      version = "~> 4.40"
    }
  }
}

variable "target_user_name" {
  type = string
  default = "ubuntu"
  description = "The target user name for locate home directory & target path."
}

variable "target_path_root" {
  type = string
  default = "/home/ubuntu"
  description = "The path for putting workspace related files."
}

variable "hub_instance_name" {
  type = string
  default = "skshell"
  description = "The name of VM/lightsail, used to differtiate from instances"
}

variable "sk_region" {
  type = string
  default = "us-east-2"
  description = "target AZ name"
} 

variable "pk_collection" {
    type = map(string)
    default = {
    "us-east-2" = "LightsailDefaultKey-us-east-2.pem"
    "ap-northeast-1" = "LightsailDefaultKey-ap-northeast-1.pem"
    }
}

variable "az_collection" {
    type = map(string)
    default = {
    "us-east-2" = "us-east-2a"
    "ap-northeast-1" = "ap-northeast-1a"
    }
}

locals {
  sk_availability_zone = lookup(var.az_collection, var.sk_region, "NA.")
  pk_this = lookup(var.pk_collection, var.sk_region, "NA.")  
}

locals {
  full_pk_this = "~/workspace/keys/aws/${local.pk_this}"
} 


provider "aws" {
  region = var.sk_region
}

resource "aws_lightsail_instance" "app" {
  #name              = "skshell"
  name 			= var.hub_instance_name
  #availability_zone = "us-east-2a"
  availability_zone  = local.sk_availability_zone
  #availability_zone  = "ap-northeast-1"
  blueprint_id       = "ubuntu_20_04"
  bundle_id          = "nano_2_0"


  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file(local.full_pk_this)}"
    host        = "${self.public_ip_address}"
  }
  
  provisioner "file" {
    source      = "conf/keys/vm_rsa"
    destination = "${var.target_path_root}/.ssh/vm_rsa"
  }  

  provisioner "file" {
    source	= "conf/keys/vm_shared"
    destination = "${var.target_path_root}/.ssh/vm_rsa.pub"
  }

  provisioner "file" {
    source	= "conf/keys/docker_passwd.txt"
    destination = "${var.target_path_root}/docker_passwd.txt"
  }
  
  provisioner "file" {
    source	= "script/docker-github-login.sh"
    destination = "${var.target_path_root}/docker-github-login.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x ${var.target_path_root}/docker-github-login.sh",
      "${var.target_path_root}/docker-github-login.sh ${var.target_path_root} ${var.target_user_name}",
    ]
  }
}

# resource "aws_lightsail_instance" "test" {
#  name              = "yak_sail"
#  availability_zone = data.aws_availability_zones.available.names[0]
#  blueprint_id      = "amazon_linux"
#  bundle_id         = "nano_1_0"
#}

resource "aws_lightsail_static_ip_attachment" "app" {
  static_ip_name = aws_lightsail_static_ip.static_ip_110.id
  instance_name  = aws_lightsail_instance.app.id
}

resource "aws_lightsail_static_ip" "static_ip_110" {
  name = "StaticIp-110"
}

#resource "aws_lightsail_instance_public_ports" "app" {
#  instance_name = aws_lightsail_instance.vps.name
#}

resource "aws_lightsail_instance_public_ports" "app" {
  instance_name = aws_lightsail_instance.app.name

  port_info {
    protocol = "tcp"
    from_port = 22
    to_port = 22
  }

  port_info {
    protocol  = "tcp"
    from_port = 10213
    to_port   = 10213
  }

  #port_info {
  #  protocol = "udp"
  #  from_port = 18513
  #  to_port = 18613
  #}
  
  port_info {
    protocol = "tcp"
    from_port = 18600
    to_port = 18600
    #description = "testing purpose only, no permanent service is running on"
  }
}

output "instance_lan_addr" {
  value = aws_lightsail_instance.app.private_ip_address
}

output "instance_wan_addr" {
  value = aws_lightsail_instance.app.public_ip_address
  
  depends_on = [
    aws_lightsail_static_ip.static_ip_110
  ]
}

output "instance_static_ip" {
  value = aws_lightsail_static_ip.static_ip_110.ip_address
}
