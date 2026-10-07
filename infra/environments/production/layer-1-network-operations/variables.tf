variable "subscription_id" {
  description = "Azure subscription identifier for the production environment (Pay-As-You-Go)."
  type        = string
}

variable "location" {
  description = "Azure region for the production environment resources."
  type        = string
}

variable "azure_devops_organization_url" {
  description = "URL of the Azure DevOps organization where the Managed DevOps Pools are registered."
  type        = string
}

variable "azure_devops_project" {
  description = "Azure DevOps project that may use the Managed DevOps Pools."
  type        = string
}
