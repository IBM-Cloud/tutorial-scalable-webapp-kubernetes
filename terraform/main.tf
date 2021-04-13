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

variable "cluster_node_flavor" {
  type    = string
  default = "bx2.4x16"
}

variable "tags" {
  type    = list(string)
  default = ["terraform", "tutorial"]
}

variable "registry_namespace_name" {
  type        = string
  default     = ""
  description = "Name of the IBM Cloud Container registry namespace."
}

variable "kubernetes_namespace" {
  type        = string
  default     = ""
  description = "Kubernetes namespace."
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

# to be used to name resources
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
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

# a new or existing VPC
resource "ibm_is_vpc" "vpc" {
  count          = var.cluster-name != "" ? 0 : 1
  name           = "${var.resource-prefix}-vpc"
  resource_group = local.resource_group_id
  tags           = var.tags
}

resource "ibm_is_public_gateway" "gateway" {
  count          = var.cluster-name != "" ? 0 : 1
  name           = "${var.resource-prefix}-gateway"
  vpc            = ibm_is_vpc.vpc.0.id
  zone           = "${var.region}-1"
  resource_group = local.resource_group_id
  tags           = var.tags
}

resource "ibm_is_subnet" "subnet" {
  count                    = var.cluster-name != "" ? 0 : 1
  name                     = "${var.resource-prefix}-subnet"
  vpc                      = ibm_is_vpc.vpc.0.id
  resource_group           = local.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway.0.id
  tags                     = var.tags
}

# a new or existing cluster
resource "ibm_container_vpc_cluster" "cluster" {
  count = var.cluster-name != "" ? 0 : 1

  # The name must be 32 or fewer characters, begin with a letter, and contain only alphanumeric characters
  name              = "${substr(var.resource-prefix, 0, 16)}${random_string.random.result}-cluster"
  vpc_id            = ibm_is_vpc.vpc.0.id
  flavor            = var.cluster_node_flavor
  worker_count      = 1
  resource_group_id = local.resource_group_id
  tags              = var.tags

  zones {
    subnet_id = ibm_is_subnet.subnet.0.id
    name      = "${var.region}-1"
  }
}

data "ibm_container_vpc_cluster" "cluster" {
  count = var.cluster-name != "" ? 1 : 0
  name  = var.cluster-name
}

# a new or existing container registry namespace to push images
resource "ibm_cr_namespace" "namespace" {
  count             = var.registry_namespace_name != "" ? 0 : 1
  name              = "${substr(var.resource-prefix, 0, 22)}${random_string.random.result}"
  resource_group_id = local.resource_group_id
}

# a namespace to deploy the app
data "ibm_container_cluster_config" "cluster" {
  cluster_name_id = local.cluster_name
  admin           = true
}

provider "kubernetes" {
  config_path = data.ibm_container_cluster_config.cluster.config_file_path
}

resource "kubernetes_namespace" "namespace" {
  count = var.kubernetes_namespace != "" ? 0 : 1
  metadata {
    name = "${var.resource-prefix}-namespace"
  }
  depends_on = [
    data.ibm_container_cluster_config.cluster
  ]
}

data "kubernetes_namespace" "namespace" {
  count = var.kubernetes_namespace != "" ? 1 : 0
  metadata {
    name = var.kubernetes_namespace
  }
  depends_on = [
    data.ibm_container_cluster_config.cluster
  ]
}

locals {
  resource_group_id       = var.resource-group != "" ? data.ibm_resource_group.group.0.id : ibm_resource_group.group.0.id
  resource_group_name     = var.resource-group != "" ? data.ibm_resource_group.group.0.name : ibm_resource_group.group.0.name
  registry_namespace_name = var.registry_namespace_name != "" ? var.registry_namespace_name : ibm_cr_namespace.namespace.0.name
  cluster_name            = var.cluster-name != "" ? data.ibm_container_vpc_cluster.cluster.0.name : ibm_container_vpc_cluster.cluster.0.name
  kubernetes_namespace    = var.kubernetes_namespace != "" ? data.kubernetes_namespace.namespace.0.metadata[0].name : kubernetes_namespace.namespace.0.metadata[0].name
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

output "cluster_name" {
  value = local.cluster_name
}

output "registry_namespace" {
  value = local.registry_namespace_name
}

output "kubernetes_namespace" {
  value = local.kubernetes_namespace
}
