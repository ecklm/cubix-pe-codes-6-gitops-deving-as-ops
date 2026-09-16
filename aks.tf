data "azurerm_client_config" "current" {}

locals {
  project_name = "project-x"
  environment  = "sbx"
}

resource "azurerm_resource_group" "this" {
  name     = "${local.project_name}-${local.environment}-aks"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "${local.project_name}-${local.environment}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  dns_prefix          = "${local.project_name}-${local.environment}"
  node_resource_group = "${azurerm_resource_group.this.name}-nodes"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_D2as_v5"

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = []
    azure_rbac_enabled     = true
  }
  local_account_disabled = true
}
resource "azurerm_role_assignment" "kube_admin" {
  scope                = resource.azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = azuread_group.platform_admins.object_id
}

resource "time_sleep" "wait_for_kube_admin" {
  depends_on = [azurerm_role_assignment.kube_admin]

  create_duration = "60s"
}

resource "local_file" "aks_kubeconfig" {
  filename = "${path.module}/kubeconfig-${local.environment}.yaml"
  content = templatefile("${path.module}/templates/kubeconfig.tpl", {
    cluster_name               = azurerm_kubernetes_cluster.this.name
    server                     = azurerm_kubernetes_cluster.this.kube_config[0].host
    certificate_authority_data = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  })
  file_permission = "0600"
}
