subscription_id         = "<production-subscription-id>"
nonprod_subscription_id = "<non-production-subscription-id>"
location                = "<azure-region>"

prod_admin_user_principal_name = "<production-admin@tenant.onmicrosoft.com>"

pipeline_federation_subjects = {
  "infra-l1" = "<subject-identifier-of-prod-infra-l1>"
  "infra-l2" = "<subject-identifier-of-prod-infra-l2>"
  "deploy"   = "<subject-identifier-of-prod-deploy>"
  "destroy"  = "<subject-identifier-of-prod-destroy>"
}

budget_amount        = 100
budget_contact_email = "<alert-recipient@example.com>"

devops_infrastructure_principal_id = "<object-id-of-the-DevOpsInfrastructure-service-principal>"
