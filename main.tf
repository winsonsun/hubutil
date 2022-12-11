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

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${var.target_path_root}/workspace/projects; mkdir -p ${var.target_path_root}/workspace/tools",
      "mkdir -p /etc/keyin",
      "sudo chmod 600 .ssh/vm_rsa",
      "ssh-keygen -F github.com || ssh-keyscan github.com >> ${var.target_path_root}/.ssh/known_hosts",
      "ssh-agent bash -c 'ssh-add ${var.target_path_root}/.ssh/vm_rsa; cd ${var.target_path_root}/workspace/projects; git clone git@github.com:winsonsun/keyin.git'",
      #"ssh-agent bash -c 'ssh-add ~/.ssh/vm_rsa; git push origin master'",
      "cd ${var.target_path_root}/workspace/projects/keyin; git checkout master; sudo ${var.target_path_root}/workspace/projects/keyin/common/init-vm.sh N US ubuntu; cd ~",
      "sudo rsync -vr ${var.target_path_root}/workspace/projects/keyin/conf /etc/keyin/",
      "sudo rsync -vr ${var.target_path_root}/workspace/projects/keyin/composeit /etc/keyin/",
      "sudo rsync -vr /etc/keyin/conf/etc-other/limits.conf /etc/security/",
      "sudo rsync -vr /etc/keyin/conf/etc-other/sysctl.conf /etc/sysctl.conf; sudo sysctl -p",
      "sleep 5",
      "sudo usermod -aG docker ${var.target_user_name}",
      "cat ~/docker_passwd.txt | sudo docker login --username winsonsun --password-stdin ; sudo docker pull winsonsun/sstool:0.2; sudo docker pull winsonsun/kktool:0.2",
      "sudo ${var.target_path_root}/workspace/projects/keyin/common/change-local-ip.sh /etc/keyin/conf/network/kcp-server.json",
      "sudo cp ${var.target_path_root}/workspace/projects/keyin/common/docker-compose-sk.service /etc/systemd/system/; sudo systemctl daemon-reload",
      "sudo systemctl enable docker-compose-sk.service; sudo systemctl start docker-compose-sk.service"
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
  
  #port_info {
  #  protocol = "tcp"
  #  from_port = 18513
  #  to_port = 18613
  #}
}

output "instance_lan_addr" {
  value = aws_lightsail_instance.app.private_ip_address
}

output "instance_wan_addr" {
  value = aws_lightsail_instance.app.public_ip_address
}

output "instance_static_ip" {
  value = aws_lightsail_static_ip.static_ip_110.ip_address
}
