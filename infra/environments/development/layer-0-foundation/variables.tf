variable "subscription_id" {
  description = "Azure subscription identifier for the development environment."
  type        = string
}

variable "location" {
  description = "Azure region for the development environment resources."
  type        = string
}

variable "pipeline_federation_subjects" {
  description = "Subject identifiers of the Azure DevOps service connections (workload identity federation), keyed by pipeline identity."
  type        = map(string)
}

variable "budget_amount" {
  description = "Monthly budget for the non-production subscription, in the billing currency."
  type        = number
}

variable "budget_contact_email" {
  description = "E-mail address that receives budget alerts."
  type        = string
}

variable "azure_devops_billing_resource_group" {
  description = "Name of the resource group that Azure DevOps created for billing (exempt from the region policy)."
  type        = string
}

variable "devops_infrastructure_principal_id" {
  description = "Object identifier of the DevOpsInfrastructure service principal (Managed DevOps Pools) in the tenant."
  type        = string
}
