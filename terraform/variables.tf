variable "fingerprint" { type = string }
variable "private_key_path" { type = string }
variable "region" { type = string }

variable "tenancy_ocid" { type = string }
variable "user_ocid" { type = string }
variable "compartment_ocid" { type = string }
variable "node_base_image_ocid" { type = string }
variable "oci_regional_service_ocid" { type = string }
variable "oci_regional_service_name" { type = string }

variable "resource_prefix" { default = "backend" }
variable "kubernetes_version" { default = "v1.29.1" }

variable "cluster_vcn_cidr" { default = "10.0.0.0/16" }
variable "api_subnet_cidr" { default = "10.0.100.0/24" }
variable "node_subnet_cidr" { default = "10.0.101.0/24" }
variable "lb_subnet_cidr" { default = "10.0.102.0/24" }
variable "bastion_subnet_cidr" { default = "10.0.103.0/24" }
variable "pod_subnet_cidr" { default = "10.0.104.0/22" }
