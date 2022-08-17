packer {
  required_plugins {
    ibmcloud = {
      version = ">=v3.0.0"
      source  = "github.com/IBM/ibmcloud"
    }
  }
}

variable "ibm_api_key" {}
variable "region" {}
variable "subnet_id" {}
variable "resource_group_id" {}
variable "vsi_base_image_name" {
  default = "ibm-ubuntu-22-04-minimal-amd64-1"
}


locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  // version = "1-2-4"
  version    = "1-${local.timestamp}"
  image_name = "packer-${local.version}"
}

/*
removed from ibmcloud-vpc
  security_group_id = ""
  // vsi_base_image_id = "r026-4e9a4dcc-15c7-4fac-b6ea-e24619059218"
  vsi_user_data_file  = ""
  vsi_interface       = "public"

    execute_command = "{{.Vars}} bash '{{.Path}}'"
*/
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
      "echo '${local.version}' >> /hello.txt",
      "sync;sync",
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

