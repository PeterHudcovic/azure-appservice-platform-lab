variable "subscription_id" {
  description = "Azure subscription identifier for the development environment."
  type        = string
}

variable "location" {
  description = "Azure region for the development environment resources."
  type        = string
}

variable "alert_email" {
  description = "E-mail address that receives the monitoring alerts of this environment."
  type        = string
}
