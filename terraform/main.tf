variable "ibmcloud_api_key" {
  type = string
}

variable "ibmcloud_timeout" {
  type    = number
  default = 600
}

variable "region" {
  type    = string
  default = "us-south"
}

variable "resource-prefix" {
  type = string
}

variable "resource-group" {
  type    = string
  default = ""
}

variable "cluster-name" {
  default = ""
}
variable "tags" {
  type    = list(string)
  default = ["terraform"]
}

variable "registry_namespace_name" {
  type        = string
  default     = ""
  description = "Name of the IBM Cloud Container registry namespace."
}

terraform {
  required_version = ">=0.13"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  ibmcloud_timeout = var.ibmcloud_timeout
}

# a new or existing resource group to create resources
resource "ibm_resource_group" "group" {
  count = var.resource-group != "" ? 0 : 1
  name  = "${var.resource-prefix}-group"
  tags  = var.tags
}

data "ibm_resource_group" "group" {
  count = var.resource-group != "" ? 1 : 0
  name  = var.resource-group
}

# a new or existing VPC and cluster
resource "ibm_is_vpc" "vpc" {
  count          = var.cluster-name != "" ? 0 : 1
  name           = "${var.resource-prefix}-vpc"
  resource_group = local.resource_group_id

  timeouts {
    create = "30m"
  }
}

resource "ibm_is_public_gateway" "gateway" {
  count = var.cluster-name != "" ? 0 : 1
  name  = "${var.resource-prefix}-gateway"
  vpc   = ibm_is_vpc.vpc.0.id
  zone  = "${var.region}-1"

  timeouts {
    create = "30m"
  }
}

resource "ibm_is_subnet" "subnet" {
  count                    = var.cluster-name != "" ? 0 : 1
  name                     = "${var.resource-prefix}-subnet"
  vpc                      = ibm_is_vpc.vpc.0.id
  resource_group           = local.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway.0.id
}
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

resource "ibm_cr_namespace" "namespace" {
  count             = var.registry_namespace_name != "" ? 0 : 1
  name              = "${substr(var.resource-prefix, 0, 21)}-${random_string.random.result}"
  resource_group_id = local.resource_group_id
}

locals {
  resource_group_id       = var.resource-group != "" ? data.ibm_resource_group.group.0.id : ibm_resource_group.group.0.id
  resource_group_name     = var.resource-group != "" ? data.ibm_resource_group.group.0.name : ibm_resource_group.group.0.name
  registry_namespace_name = var.registry_namespace_name != "" ? var.registry_namespace_name : ibm_cr_namespace.namespace.0.name
}

output "resource_group_id" {
  value = local.resource_group_id
}

output "region" {
  value = var.region
}

output "resource_group_name" {
  value = local.resource_group_name
}

output "registry_namespace" {
  value = local.registry_namespace_name
}
