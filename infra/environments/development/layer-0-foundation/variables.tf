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