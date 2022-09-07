locals {
  name = "${var.prefix}-packer"
}
resource "ibm_is_vpc" "packer" {
  name                      = local.name
  resource_group            = local.resource_group
  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "zone" {
  name = local.name
  zone = local.zone
  vpc  = ibm_is_vpc.packer.id
  cidr = "10.0.0.0/16"
}

resource "ibm_is_subnet" "zone" {
  name            = local.name
  resource_group  = local.resource_group
  vpc             = ibm_is_vpc.packer.id
  zone            = ibm_is_vpc_address_prefix.zone.zone
  ipv4_cidr_block = "10.0.0.0/24"
}


output "packer" {
  value = <<-EOT
    export PKR_VAR_subnet_id="${ibm_is_subnet.zone.id}"
    export PKR_VAR_resource_group_id="${local.resource_group}"
    export PKR_VAR_region="${var.region}"
  EOT
}
