resource "oci_containerengine_cluster" "cluster" {
  compartment_id     = data.oci_identity_compartment.cluster_compartment.id
  name               = "${var.resource_prefix}-cluster"
  kubernetes_version = var.kubernetes_version
  vcn_id             = oci_core_vcn.cluster_vcn.id
  type               = "BASIC_CLUSTER"

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  endpoint_config {
    is_public_ip_enabled = "false"
    subnet_id            = oci_core_subnet.api_subnet.id
  }

  image_policy_config {
    is_policy_enabled = "false"
  }

  options {
    service_lb_subnet_ids = [
      oci_core_subnet.lb_subnet.id
    ]
  }
}

resource "oci_containerengine_node_pool" "node_pool" {
  cluster_id     = oci_containerengine_cluster.cluster.id
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
  name           = "${var.resource_prefix}-node-pool-a"
  node_shape     = "VM.Standard.A1.Flex"

  kubernetes_version = var.kubernetes_version

  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.availiability_domains.availability_domains[0]["name"]
      subnet_id           = oci_core_subnet.node_subnet.id
    }
    size                                = 2
    is_pv_encryption_in_transit_enabled = "true"
    node_pool_pod_network_option_details {
      cni_type          = "OCI_VCN_IP_NATIVE"
      max_pods_per_node = "31"
      pod_subnet_ids = [
        oci_core_subnet.pod_subnet.id
      ]
    }
  }

  node_eviction_node_pool_settings {
    eviction_grace_duration = "PT1H"
  }

  node_shape_config {
    memory_in_gbs = 12
    ocpus         = 2
  }

  node_source_details {
    image_id                = data.oci_core_image.node_base_image.id
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = 50
  }
}

resource "oci_bastion_bastion" "bastion" {
  compartment_id   = data.oci_identity_compartment.cluster_compartment.id
  name             = "${var.resource_prefix}bastion"
  bastion_type     = "STANDARD"
  target_subnet_id = oci_core_subnet.bastion_subnet.id

  client_cidr_block_allow_list = [
    "0.0.0.0/0"
  ]
  dns_proxy_status           = "DISABLED"
  max_session_ttl_in_seconds = "10800"
}
