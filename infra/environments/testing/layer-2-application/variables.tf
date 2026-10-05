variable "subscription_id" {
  description = "Azure subscription identifier for the testing environment (shared non-production subscription)."
  type        = string
}

variable "location" {
  description = "Azure region for the testing environment resources."
  type        = string
}

variable "alert_email" {
  description = "E-mail address that receives the monitoring alerts of this environment."
  type        = string
}

# Passed in instead of a Microsoft Graph lookup, so the pipeline identities need no Entra ID permissions
variable "app_client_id" {
  description = "Client ID of the Entra ID app registration for user sign-in, created in layer 0."
  type        = string
}
