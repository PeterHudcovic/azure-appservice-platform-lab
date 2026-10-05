variable "subscription_id" {
  description = "Azure subscription identifier for the production environment (Pay-As-You-Go)."
  type        = string
}

variable "nonprod_subscription_id" {
  description = "Azure subscription identifier of the non-production subscription (shared package storage, development and testing NAT addresses)."
  type        = string
}

variable "location" {
  description = "Azure region for the production environment resources."
  type        = string
}

variable "prod_admin_user_principal_name" {
  description = "User principal name of the production administrator account (MFA required), which gets Reader and eligible PIM roles."
  type        = string
}

variable "pipeline_federation_subjects" {
  description = "Subject identifiers of the production Azure DevOps service connections (workload identity federation), keyed by pipeline identity. Empty until the service connections exist."
  type        = map(string)
  default     = {}
}

variable "budget_amount" {
  description = "Monthly budget for the production subscription, in the billing currency."
  type        = number
}

variable "budget_contact_email" {
  description = "E-mail address that receives budget alerts."
  type        = string
}

variable "devops_infrastructure_principal_id" {
  description = "Object identifier of the DevOpsInfrastructure service principal (Managed DevOps Pools) in the tenant."
  type        = string
}
