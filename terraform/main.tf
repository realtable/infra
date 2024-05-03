terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.39.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

data "oci_identity_compartment" "cluster_compartment" {
  id = var.compartment_ocid
}

data "oci_identity_availability_domains" "availiability_domains" {
  compartment_id = data.oci_identity_compartment.cluster_compartment.id
}

data "oci_core_image" "node_base_image" {
  image_id = var.node_base_image_ocid
}
