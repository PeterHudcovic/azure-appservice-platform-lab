variable "subscription_id" {
  description = "Azure subscription identifier for the testing environment (shared non-production subscription)."
  type        = string
}

variable "location" {
  description = "Azure region for the testing environment resources."
  type        = string
}

variable "pipeline_federation_subjects" {
  description = "Subject identifiers of the testing Azure DevOps service connections (workload identity federation), keyed by pipeline identity. Empty until the service connections exist."
  type        = map(string)
  default     = {}
}

variable "devops_infrastructure_principal_id" {
  description = "Object identifier of the DevOpsInfrastructure service principal (Managed DevOps Pools) in the tenant."
  type        = string
}
