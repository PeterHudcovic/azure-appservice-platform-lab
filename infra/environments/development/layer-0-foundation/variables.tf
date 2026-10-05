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