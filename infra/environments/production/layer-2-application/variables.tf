variable "subscription_id" {
  description = "Azure subscription identifier for the production environment (Pay-As-You-Go)."
  type        = string
}

variable "location" {
  description = "Azure region for the production environment resources."
  type        = string
}

variable "alert_email" {
  description = "E-mail address that receives the monitoring alerts of this environment."
  type        = string
}
