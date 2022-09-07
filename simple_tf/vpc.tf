data "ibm_is_images" "images" {
  visibility = "private"
}

data "ibm_resource_tag" "image_tag" {
  for_each = { for image in data.ibm_is_images.images.images : image.id => image.crn }

  resource_id = each.value
}

locals {
  tag_name = "${var.prefix}-stage"
  all_images = [for image in data.ibm_is_images.images.images : {
    id : image.id,
    name : image.name
    crn : image.crn
    tags : data.ibm_resource_tag.image_tag[image.id].tags
  }]
  all_tagged_images        = [for image in local.all_images : image if contains(image.tags, local.tag_name)]
  all_tagged_images_length = length(local.all_tagged_images)
  image_id                 = local.all_tagged_images[0].id
  image_name               = local.all_tagged_images[0].name
  name                     = "${var.prefix}-simple"
  profile                  = "cx2-2x4"
}

// image that was tagged, verify there was only one tagged image
output "the_one_tagged_image" {
  value = {
    id   = local.image_id
    name = local.image_name
  }
  precondition {
    condition     = local.all_tagged_images_length == 1
    error_message = "the must be exactly 1 tagged image"
  }
}

data "ibm_is_ssh_key" "ssh_key" {
  name = var.ssh_key_name
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

resource "ibm_is_subnet_reserved_ip" "instance" {
  subnet = ibm_is_subnet.zone.id
  name   = local.name
  // address = replace(ibm_is_subnet.zone.ipv4_cidr_block, "0/24", "7")
}

resource "ibm_is_security_group" "simple_all" {
  name           = local.name
  resource_group = local.resource_group
  vpc            = ibm_is_vpc.packer.id
}

resource "ibm_is_security_group_rule" "simple_inbound_all" {
  group     = ibm_is_security_group.simple_all.id
  direction = "inbound"
}
resource "ibm_is_security_group_rule" "simple_outbound_all" {
  group     = ibm_is_security_group.simple_all.id
  direction = "outbound"
}

resource "ibm_is_instance" "simple" {
  name           = local.name
  image          = local.image_id
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
    security_groups = [ibm_is_security_group.simple_all.id]
  }
}
resource "ibm_is_floating_ip" "zone" {
  name           = ibm_is_instance.simple.name
  target         = ibm_is_instance.simple.primary_network_interface[0].id
  resource_group = local.resource_group
}

output "simple" {
  value = <<-EOT
  curl ${ibm_is_floating_ip.zone.address}
  ssh root@${ibm_is_floating_ip.zone.address}
  ${ibm_is_instance.simple.primary_network_interface[0].primary_ip[0].address} ${ibm_is_instance.simple.name}
  EOT
}
output "public_ip" {
  value = ibm_is_floating_ip.zone.address
}