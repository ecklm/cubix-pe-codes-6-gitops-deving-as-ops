variable "location" {
  description = "Azure region for the AKS resource group and cluster."
  type        = string
  default     = "swedencentral"
}

variable "parent_domain" {
  description = "Parent DNS domain used to derive the project zone."
  type        = string
  default     = "ecklm.cubix.ecklm.com"
}

variable "parent_domain_resource_group_name" {
  description = "Resource group containing the parent DNS zone."
  type        = string
  default     = "course-baseline"
}
