variable "subscription_id" {
  description = "Azure subscription identifier for the development environment."
  type        = string
}

variable "location" {
  description = "Azure region for the development environment resources."
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
