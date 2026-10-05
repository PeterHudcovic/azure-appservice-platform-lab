# Managed DevOps Pools: private Azure Pipelines agents inside the development virtual network.
# Pool "infra" runs Terraform for the layers (reaches the vaults), pool "app" deploys the application.
# The DevOpsInfrastructure service gets its network roles in layer 0.
resource "azurerm_dev_center" "main" {
  name                = "dc-sits-${local.environment}-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.network.name
  location            = data.azurerm_resource_group.network.location
  tags                = local.tags
}

resource "azurerm_dev_center_project" "main" {
  name                = "dcp-sits-${local.environment}-${local.region_code}"
  resource_group_name = data.azurerm_resource_group.network.name
  location            = data.azurerm_resource_group.network.location
  dev_center_id       = azurerm_dev_center.main.id
  tags                = local.tags
}

locals {
  agent_pools = {
    infra = "snet-agents-infra"
    app   = "snet-agents-app"
  }
}

resource "azurerm_managed_devops_pool" "main" {
  for_each = local.agent_pools

  name                  = "mdp-sits-${local.environment}-${each.key}-${local.region_code}"
  resource_group_name   = data.azurerm_resource_group.network.name
  location              = data.azurerm_resource_group.network.location
  dev_center_project_id = azurerm_dev_center_project.main.id
  maximum_concurrency   = 1
  tags                  = local.tags

  azure_devops_organization {
    organization {
      url         = var.azure_devops_organization_url
      parallelism = 1
      projects    = [var.azure_devops_project]
    }
  }

  # Stateless: every job gets a fresh agent; no standby agents (cost)
  stateless_agent {}

  # Standard_D2ads_v5: the subscription has Managed DevOps Pools quota for the DADSv5 family (2 pools x 2 vCPU)
  virtual_machine_scale_set_fabric {
    sku_name  = "Standard_D2ads_v5"
    subnet_id = azurerm_subnet.main[each.value].id

    image {
      # Azure stores the image as "ubuntu-24.04" with these aliases; the code matches it to avoid drift
      well_known_image_name = "ubuntu-24.04"
      aliases               = ["ubuntu-24.04/latest", "ubuntu-24.04"]
    }
  }
}
