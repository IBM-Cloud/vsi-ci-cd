data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

locals {
  resource_group = data.ibm_resource_group.group.id
  zone           = "${var.region}-1"
}
