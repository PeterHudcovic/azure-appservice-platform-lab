# Managed DevOps Pools place agents in the production subnets through the DevOpsInfrastructure service.
# The service needs Reader and Network Contributor on the virtual network. The roles are granted on the
# network resource group here, so the layer 1 pipeline identity never needs permission to assign roles.
resource "azurerm_role_assignment" "devops_infrastructure_network" {
  for_each = toset(["Reader", "Network Contributor"])

  scope                = azurerm_resource_group.layers["network"].id
  role_definition_name = each.key
  principal_id         = var.devops_infrastructure_principal_id
}
