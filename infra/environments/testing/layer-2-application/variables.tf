variable "subscription_id" {
  description = "Azure subscription identifier for the testing environment (shared non-production subscription)."
  type        = string
}

variable "location" {
  description = "Azure region for the testing environment resources."
  type        = string
}
