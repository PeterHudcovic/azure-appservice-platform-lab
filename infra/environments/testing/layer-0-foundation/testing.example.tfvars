subscription_id = "<non-production-subscription-id>"
location        = "<azure-region>"

pipeline_federation_subjects = {
  "infra-l1" = "<subject-identifier-of-test-infra-l1>"
  "infra-l2" = "<subject-identifier-of-test-infra-l2>"
  "deploy"   = "<subject-identifier-of-test-deploy>"
  "destroy"  = "<subject-identifier-of-test-destroy>"
}

devops_infrastructure_principal_id = "<object-id-of-the-DevOpsInfrastructure-service-principal>"
