variable "subscription_id" {
  description = "Azure subscription identifier for the development environment."
  type        = string
}

variable "location" {
  description = "Azure region for the development environment resources."
  type        = string
}

variable "dev_infra_l1_federation_subject" {
  description = "Subject identifier of the Azure DevOps service connection dev-infra-l1 (workload identity federation)."
  type        = string
}