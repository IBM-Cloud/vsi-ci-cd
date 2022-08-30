packer {
  required_plugins {
    ibmcloud = {
      version = ">=v3.0.0"
      source  = "github.com/IBM/ibmcloud"
    }
  }
}

variable "prefix" {}
variable "ibm_api_key" {}
variable "region" {}
variable "subnet_id" {}
variable "resource_group_id" {}
variable "vsi_base_image_name" {
  default = "ibm-ubuntu-22-04-minimal-amd64-1"
}


locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  # version = "1-0-11"
  version = local.timestamp
  image_name = "${var.prefix}-${local.version}"
}

source "ibmcloud-vpc" "ubuntu" {
  timeout = "30m"
  api_key = var.ibm_api_key
  region  = var.region

  subnet_id         = var.subnet_id
  resource_group_id = var.resource_group_id

  vsi_base_image_name = var.vsi_base_image_name
  vsi_profile         = "cx2-2x4"
  image_name          = local.image_name

  communicator = "ssh"
  ssh_username = "root"
  ssh_port     = 22
  ssh_timeout  = "15m"
}

build {
  sources = [
    "source.ibmcloud-vpc.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "set -x",
      "echo '@reboot echo ${local.version} $(hostname) $(hostname -I) > /var/www/html/index.html' | crontab",
      "crontab -l",
      "export DEBIAN_FRONTEND=noninteractive",
      "apt -qq -y update < /dev/null",
      "sleep 10",
      "apt -qq -y update < /dev/null",
      "apt -qq -y install nginx < /dev/null",
      "sync;sync",
    ]
  }
  
  post-processor "shell-local" {
    inline = [
      "echo foo",
      "echo bar",
      ]
  }

  post-processor "manifest" {
    strip_path = true
    custom_data = {
      version    = local.version
      image_name = local.image_name
    }
  }

}

