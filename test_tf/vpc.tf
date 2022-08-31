# todo names of resources is off

data "ibm_is_ssh_key" "ssh_key" {
  name = var.ssh_key_name
}

data "ibm_is_image" "name" {
  name = var.image_name
}

locals {
  prefix  = "${var.prefix}-packertest"
  profile = "cx2-2x4"
}
resource "ibm_is_vpc" "packer" {
  name                      = local.prefix
  resource_group            = local.resource_group
  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "zone" {
  name = local.prefix
  zone = local.zone
  vpc  = ibm_is_vpc.packer.id
  cidr = "10.0.0.0/16"
}

resource "ibm_is_subnet" "zone" {
  name            = local.prefix
  resource_group  = local.resource_group
  vpc             = ibm_is_vpc.packer.id
  zone            = ibm_is_vpc_address_prefix.zone.zone
  ipv4_cidr_block = "10.0.0.0/24"
}

resource "ibm_is_subnet_reserved_ip" "instance" {
  subnet = ibm_is_subnet.zone.id
  name   = local.prefix
  // address = replace(ibm_is_subnet.zone.ipv4_cidr_block, "0/24", "7")
}


resource "ibm_is_security_group" "test_all" {
  name           = local.prefix
  resource_group = local.resource_group
  vpc            = ibm_is_vpc.packer.id
}

resource "ibm_is_security_group_rule" "test_inbound_all" {
  group     = ibm_is_security_group.test_all.id
  direction = "inbound"
}
resource "ibm_is_security_group_rule" "test_outbound_all" {
  group     = ibm_is_security_group.test_all.id
  direction = "outbound"
}



resource "ibm_is_instance" "test" {
  name           = local.prefix
  image          = data.ibm_is_image.name.id
  profile        = local.profile
  vpc            = ibm_is_vpc.packer.id
  zone           = ibm_is_subnet.zone.zone
  keys           = [data.ibm_is_ssh_key.ssh_key.id]
  resource_group = local.resource_group
  primary_network_interface {
    subnet = ibm_is_subnet.zone.id
    primary_ip {
      reserved_ip = ibm_is_subnet_reserved_ip.instance.reserved_ip
    }
    security_groups = [ibm_is_security_group.test_all.id]
  }
}
resource "ibm_is_floating_ip" "zone" {
  name           = ibm_is_instance.test.name
  target         = ibm_is_instance.test.primary_network_interface[0].id
  resource_group = local.resource_group
}

output "test" {
  value = <<-EOT
  curl ${ibm_is_floating_ip.zone.address}
  ssh root@${ibm_is_floating_ip.zone.address}
  ${ibm_is_instance.test.primary_network_interface[0].primary_ipv4_address} ${ibm_is_instance.test.name}
  EOT
}