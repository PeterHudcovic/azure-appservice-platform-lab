subscription_id = "<non-production-subscription-id>"
location        = "<azure-region>"

pipeline_federation_subjects = {
  "infra-l1" = "<subject-identifier-of-dev-infra-l1>"
  "infra-l2" = "<subject-identifier-of-dev-infra-l2>"
  "deploy"   = "<subject-identifier-of-dev-deploy>"
  "destroy"  = "<subject-identifier-of-dev-destroy>"
  "build"    = "<subject-identifier-of-build>"
}

budget_amount        = 100
budget_contact_email = "<alert-recipient@example.com>"

azure_devops_billing_resource_group = "<azure-devops-billing-resource-group-name>"