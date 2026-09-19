variable "location" {
  description = "Azure region for the AKS resource group and cluster."
  type        = string
  default     = "swedencentral"
}

variable "env_name" {
  description = "Short name of the environment."
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "parent_domain" {
  description = "Parent DNS domain used to derive the project zone."
  type        = string
  default     = "ecklm.az.cubix-pe.hu"
}

variable "parent_domain_resource_group_name" {
  description = "Resource group containing the parent DNS zone."
  type        = string
  default     = "course-baseline"
}

locals {
  resource_basename = "${var.project_name}-${var.env_name}"
}

data "azurerm_client_config" "current" {}

resource "terraform_data" "workspace_guard" {
  input = var.env_name

  lifecycle {
    precondition {
      condition     = terraform.workspace == var.env_name
      error_message = "Selected workspace must match env_name. Run terraform workspace select ${var.env_name} before using ${var.env_name}.tfvars."
    }
  }
}
