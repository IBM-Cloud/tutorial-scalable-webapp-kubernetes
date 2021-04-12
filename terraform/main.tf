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

variable "tags" {
  type    = list(string)
  default = ["terraform"]
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

resource "ibm_resource_group" "group" {
  count = var.resource-group != "" ? 0 : 1
  name  = "${var.resource-prefix}-group"
  tags  = var.tags
}

data "ibm_resource_group" "group" {
  count = var.resource-group != "" ? 1 : 0
  name  = var.resource-group
}
