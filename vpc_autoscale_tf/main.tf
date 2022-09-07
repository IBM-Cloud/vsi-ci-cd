/*
see variables.tf
*/
locals {
  name    = "${var.prefix}-autoscale"
  current = var.current
  next    = 1 - local.current
  state = {
    0 = {
      image_id   = data.ibm_is_image.i0.id
      image_name = data.ibm_is_image.i0.name
    },
    1 = {
      image_id   = data.ibm_is_image.i1.id
      image_name = data.ibm_is_image.i1.name
    }
  }
}

data "ibm_is_image" "i0" {
  name = var.image_name_0
}

data "ibm_is_image" "i1" {
  name = var.image_name_1
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name           = local.name
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_subnet" "subnet" {
  count                    = 2
  name                     = "${local.name}-${count.index + 1}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.region}-${count.index + 1}"
  resource_group           = data.ibm_resource_group.group.id
  total_ipv4_address_count = "256"
}

resource "ibm_is_security_group" "autoscale_security_group" {
  name           = "${local.name}-autoscale-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "maintenance_security_group" {
  name           = "${local.name}-maintenance-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "lb_security_group" {
  name           = "${local.name}-lb-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "autoscale_security_group_rule_icmp" {
  group     = ibm_is_security_group.autoscale_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  icmp {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "autoscale_security_group_rule_tcp_22" {
  group     = ibm_is_security_group.autoscale_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "autoscale_security_group_rule_tcp_80" {
  group     = ibm_is_security_group.autoscale_security_group.id
  direction = "inbound"
  remote    = ibm_is_security_group.lb_security_group.id
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "autoscale_security_group_rule_tcp_443" {
  group     = ibm_is_security_group.autoscale_security_group.id
  direction = "inbound"
  remote    = ibm_is_security_group.lb_security_group.id
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "autoscale_security_group_rule_tcp_outbound" {
  group     = ibm_is_security_group.autoscale_security_group.id
  direction = "outbound"
  remote    = ibm_is_security_group.maintenance_security_group.id
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "maintenance_security_group_rule_tcp_22" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "inbound"
  remote    = ibm_is_security_group.autoscale_security_group.id
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "maintenance_security_group_rule_tcp_outbound_80" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "maintenance_security_group_rule_tcp_outbound_443" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 443
    port_max = 443
  }
}


resource "ibm_is_security_group_rule" "maintenance_security_group_rule_tcp_outbound" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "maintenance_security_group_rule_udp_outbound" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  udp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "lb_security_group_rule_tcp_80" {
  group     = ibm_is_security_group.lb_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "lb_security_group_rule_tcp_443" {
  group     = ibm_is_security_group.lb_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "lb_security_group_rule_tcp_80_outbound" {
  group     = ibm_is_security_group.lb_security_group.id
  direction = "outbound"
  remote    = ibm_is_security_group.autoscale_security_group.id
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "lb_security_group_rule_tcp_443_outbound" {
  group     = ibm_is_security_group.lb_security_group.id
  direction = "outbound"
  remote    = ibm_is_security_group.autoscale_security_group.id
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_lb" "lb" {
  name            = "${local.name}-lb"
  subnets         = ibm_is_subnet.subnet.*.id
  resource_group  = data.ibm_resource_group.group.id
  security_groups = [ibm_is_security_group.lb_security_group.id]
}

resource "ibm_is_lb_pool" "lb-pool" {
  lb                 = ibm_is_lb.lb.id
  name               = "${local.name}-lb-pool"
  protocol           = var.enable_end_to_end_encryption ? "https" : "http"
  algorithm          = "round_robin"
  health_delay       = "15"
  health_retries     = "2"
  health_timeout     = "5"
  health_type        = var.enable_end_to_end_encryption ? "https" : "http"
  health_monitor_url = "/"
  depends_on         = [time_sleep.wait_30_seconds]
}

resource "ibm_is_lb_listener" "lb-listener" {
  lb                   = ibm_is_lb.lb.id
  port                 = var.certificate_crn == "" ? "80" : "443"
  protocol             = var.certificate_crn == "" ? "http" : "https"
  default_pool         = element(split("/", ibm_is_lb_pool.lb-pool.id), 1)
  certificate_instance = var.certificate_crn == "" ? "" : var.certificate_crn
}

resource "ibm_is_instance_template" "instance_template" {
  count          = 2
  name           = "${local.name}-${count.index}"
  image          = local.state[count.index].image_id
  profile        = "cx2-2x4"
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet[0].id
    security_groups = [ibm_is_security_group.autoscale_security_group.id, ibm_is_security_group.maintenance_security_group.id]
  }

  vpc  = ibm_is_vpc.vpc.id
  zone = "${var.region}-1"
  keys = [data.ibm_is_ssh_key.sshkey.id]
  // user_data = var.enable_end_to_end_encryption ? file("./scripts/install-software-ssl.sh") : file("./scripts/install-software.sh")
}

resource "ibm_is_instance_group" "instance_group" {
  name               = "${local.name}-instance-group"
  instance_template  = ibm_is_instance_template.instance_template[local.current].id
  instance_count     = 2
  subnets            = ibm_is_subnet.subnet.*.id
  load_balancer      = ibm_is_lb.lb.id
  load_balancer_pool = element(split("/", ibm_is_lb_pool.lb-pool.id), 1)
  application_port   = var.enable_end_to_end_encryption ? 443 : 80
  resource_group     = data.ibm_resource_group.group.id

  depends_on = [ibm_is_lb_listener.lb-listener, ibm_is_lb_pool.lb-pool, ibm_is_lb.lb]
}

resource "ibm_is_instance_group_manager" "instance_group_manager" {
  name                 = "${local.name}-instance-group-manager"
  aggregation_window   = 90
  instance_group       = ibm_is_instance_group.instance_group.id
  cooldown             = 120
  manager_type         = "autoscale"
  enable_manager       = true
  min_membership_count = 2
  max_membership_count = 3
}

resource "ibm_is_instance_group_manager_policy" "cpuPolicy" {
  instance_group         = ibm_is_instance_group.instance_group.id
  instance_group_manager = ibm_is_instance_group_manager.instance_group_manager.manager_id
  metric_type            = "cpu"
  metric_value           = 10
  policy_type            = "target"
  name                   = "${local.name}-instance-group-manager-policy"
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [ibm_is_lb.lb]

  destroy_duration = "30s"
}


output "load_balancer_hostname" {
  value = ibm_is_lb.lb.hostname
}

output "instance_group_id" {
  value = ibm_is_instance_group.instance_group.id
}

output "current" {
  value = {
    current            = local.current
    next               = local.next
    image_id_current   = local.state[local.current].image_id
    image_name_current = local.state[local.current].image_name
    image_id_next      = local.state[local.next].image_id
    image_name_next    = local.state[local.next].image_name
  }
}
