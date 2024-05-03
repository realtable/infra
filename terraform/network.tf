# core network resources

resource "oci_core_vcn" "cluster_vcn" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-vcn"

  cidr_blocks = [
    var.cluster_vcn_cidr,
  ]
  dns_label               = "cluster"
  ipv6private_cidr_blocks = []
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-internet-gateway"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  enabled        = "true"
  route_table_id = oci_core_vcn.cluster_vcn.default_route_table_id
}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-nat-gateway"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  block_traffic  = "false"
  public_ip_id   = oci_core_public_ip.nat_gateway_public_ip.id
  route_table_id = oci_core_vcn.cluster_vcn.default_route_table_id
}

resource "oci_core_public_ip" "nat_gateway_public_ip" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-nat-gateway-public-ip"
  lifetime       = "RESERVED"
}

resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-service-gateway"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  services {
    service_id = var.oci_regional_service_ocid
  }
}

resource "oci_core_default_dhcp_options" "default_dhcp_options" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-default-dhcp-options"

  domain_name_type           = "CUSTOM_DOMAIN"
  manage_default_resource_id = oci_core_vcn.cluster_vcn.default_dhcp_options_id

  options {
    custom_dns_servers = [
    ]
    server_type = "VcnLocalPlusInternet"
    type        = "DomainNameServer"
  }
  options {
    search_domain_names = [
      "cluster.oraclevcn.com",
    ]
    type = "SearchDomain"
  }
}

# subnets

resource "oci_core_subnet" "api_subnet" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-api-subnet"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  cidr_block                 = var.api_subnet_cidr
  dhcp_options_id            = oci_core_vcn.cluster_vcn.default_dhcp_options_id
  dns_label                  = "api"
  ipv6cidr_blocks            = []
  prohibit_internet_ingress  = "true"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.api_route_table.id
  security_list_ids = [
    oci_core_security_list.api_security_list.id,
  ]
}

resource "oci_core_subnet" "node_subnet" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-node-subnet"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  cidr_block                 = var.node_subnet_cidr
  dhcp_options_id            = oci_core_vcn.cluster_vcn.default_dhcp_options_id
  dns_label                  = "node"
  ipv6cidr_blocks            = []
  prohibit_internet_ingress  = "true"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.node_route_table.id
  security_list_ids = [
    oci_core_vcn.cluster_vcn.default_security_list_id,
  ]
}

resource "oci_core_subnet" "pod_subnet" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-pod-subnet"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  cidr_block                 = var.pod_subnet_cidr
  dhcp_options_id            = oci_core_vcn.cluster_vcn.default_dhcp_options_id
  dns_label                  = "pod"
  ipv6cidr_blocks            = []
  prohibit_internet_ingress  = "true"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.pod_route_table.id
  security_list_ids = [
    oci_core_security_list.pod_security_list.id,
  ]
}

resource "oci_core_subnet" "lb_subnet" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-lb-subnet"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  cidr_block                 = var.lb_subnet_cidr
  dhcp_options_id            = oci_core_vcn.cluster_vcn.default_dhcp_options_id
  dns_label                  = "lb"
  ipv6cidr_blocks            = []
  prohibit_internet_ingress  = "false"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_route_table.lb_route_table.id
  security_list_ids = [
    oci_core_security_list.lb_security_list.id,
  ]
}

resource "oci_core_subnet" "bastion_subnet" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-bastion-subnet"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  cidr_block                 = var.bastion_subnet_cidr
  dhcp_options_id            = oci_core_vcn.cluster_vcn.default_dhcp_options_id
  dns_label                  = "bastion"
  ipv6cidr_blocks            = []
  prohibit_internet_ingress  = "true"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_vcn.cluster_vcn.default_route_table_id
  security_list_ids = [
    oci_core_security_list.bastion_security_list.id,
  ]
}

# route tables

resource "oci_core_default_route_table" "default_route_table" {
  compartment_id             = data.oci_identity_compartment.cluster_compartment.id
  display_name               = "${var.resource_prefix}-default-route-table"
  manage_default_resource_id = oci_core_vcn.cluster_vcn.default_route_table_id
}

resource "oci_core_route_table" "api_route_table" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-api-route-table"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }
  route_rules {
    destination       = var.oci_regional_service_name
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
  }
}

resource "oci_core_route_table" "node_route_table" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-node-route-table"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }
  route_rules {
    destination       = var.oci_regional_service_name
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
  }
}

resource "oci_core_route_table" "pod_route_table" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-pod-route-table"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }
  route_rules {
    destination       = var.oci_regional_service_name
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
  }
}

resource "oci_core_route_table" "lb_route_table" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-lb-route-table"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

# security lists

resource "oci_core_default_security_list" "default_security_list" {
  compartment_id             = data.oci_identity_compartment.cluster_compartment.id
  display_name               = "${var.resource_prefix}-default-security-list"
  manage_default_resource_id = oci_core_vcn.cluster_vcn.default_security_list_id

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    icmp_options {
      type = "3"
      code = "4"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
}

resource "oci_core_security_list" "api_security_list" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-api-security-list"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  egress_security_rules {
    destination      = var.oci_regional_service_name
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
  }
  egress_security_rules {
    destination      = var.oci_regional_service_name
    destination_type = "SERVICE_CIDR_BLOCK"
    icmp_options {
      type = "3"
      code = "4"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    destination      = var.node_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      max = "10250"
      min = "10250"
    }
  }
  egress_security_rules {
    destination      = var.node_subnet_cidr
    destination_type = "CIDR_BLOCK"
    icmp_options {
      type = "3"
      code = "4"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    destination      = var.pod_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.bastion_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.node_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.node_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  ingress_security_rules {
    icmp_options {
      type = "3"
      code = "4"
    }
    protocol    = "1"
    source      = var.node_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.pod_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.pod_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
}

resource "oci_core_security_list" "node_security_list" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-node-security-list"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  egress_security_rules {
    destination      = var.pod_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      type = "3"
      code = "4"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    destination      = var.oci_regional_service_name
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
  }
  egress_security_rules {
    destination      = var.api_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  egress_security_rules {
    destination      = var.api_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.bastion_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.api_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "10250"
      min = "10250"
    }
  }
  ingress_security_rules {
    icmp_options {
      type = "3"
      code = "4"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.lb_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "10256"
      min = "10256"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.lb_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "32767"
      min = "30000"
    }
  }
}

resource "oci_core_security_list" "pod_security_list" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-pod-security-list"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    destination      = var.api_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  egress_security_rules {
    destination      = var.api_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  egress_security_rules {
    destination      = var.oci_regional_service_name
    destination_type = "SERVICE_CIDR_BLOCK"
    icmp_options {
      type = "3"
      code = "4"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    destination      = var.pod_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  egress_security_rules {
    destination      = var.oci_regional_service_name
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.pod_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    protocol    = "all"
    source      = var.api_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    protocol    = "all"
    source      = var.node_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
}


resource "oci_core_security_list" "lb_security_list" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-lb-security-list"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  egress_security_rules {
    destination      = var.node_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      max = "10256"
      min = "10256"
    }
  }
  egress_security_rules {
    destination      = var.node_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      max = "32767"
      min = "30000"
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "103.21.244.0/22"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "103.22.200.0/22"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "103.31.4.0/22"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "104.16.0.0/13"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "104.24.0.0/14"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "108.162.192.0/18"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "131.0.72.0/22"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "141.101.64.0/18"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "162.158.0.0/15"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "172.64.0.0/13"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "173.245.48.0/20"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "188.114.96.0/20"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "190.93.240.0/20"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "197.234.240.0/22"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "198.41.128.0/17"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
}

resource "oci_core_security_list" "bastion_security_list" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  display_name   = "${var.resource_prefix}-bastion-security-list"
  vcn_id         = oci_core_vcn.cluster_vcn.id

  egress_security_rules {
    destination      = var.api_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  egress_security_rules {
    destination      = var.node_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
}
