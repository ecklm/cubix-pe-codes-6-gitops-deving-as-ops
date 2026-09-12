locals {
  project_domain   = "${local.project_name}.${local.environment}.${var.parent_domain}"
  dns_txt_owner_id = replace(local.project_domain, ".", "-")
}

resource "azurerm_resource_group" "dns" {
  name     = "${local.project_name}-${local.environment}-dns"
  location = var.location
}

resource "azurerm_dns_zone" "this" {
  name                = local.project_domain
  resource_group_name = azurerm_resource_group.dns.name
}

resource "azurerm_dns_ns_record" "parent_delegation" {
  name                = "${local.project_name}.${local.environment}"
  zone_name           = var.parent_domain
  resource_group_name = var.parent_domain_resource_group_name
  ttl                 = 300
  records             = azurerm_dns_zone.this.name_servers
}

resource "azurerm_user_assigned_identity" "external_dns" {
  name                = "${local.project_name}-${local.environment}-externaldns"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "external_dns_zone_contributor" {
  scope                = azurerm_dns_zone.this.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
}

resource "azurerm_federated_identity_credential" "external_dns" {
  name                      = "external-dns"
  user_assigned_identity_id = azurerm_user_assigned_identity.external_dns.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.this.oidc_issuer_url
  subject                   = "system:serviceaccount:external-dns:external-dns"
}

resource "helm_release" "external_dns" {
  provider = helm.sbx

  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = "1.20.0"
  namespace        = "external-dns"
  create_namespace = true

  values = [
    yamlencode({
      logFormat = "text"
      podLabels = {
        "azure.workload.identity/use" = "true"
      }
      sources = ["ingress"]
      provider = {
        name = "azure"
      }
      policy             = "sync"
      registry           = "txt"
      triggerLoopOnEvent = true
      txtOwnerId         = local.dns_txt_owner_id
      domainFilters      = [local.project_domain]
      serviceAccount = {
        labels = {
          "azure.workload.identity/use" = "true"
        }
        annotations = {
          "azure.workload.identity/client-id" = azurerm_user_assigned_identity.external_dns.client_id
        }
      }
      secretConfiguration = {
        enabled = true
        data = {
          "azure.json" = jsonencode({
            tenantId                     = data.azurerm_client_config.current.tenant_id
            subscriptionId               = data.azurerm_client_config.current.subscription_id
            resourceGroup                = azurerm_resource_group.dns.name
            useWorkloadIdentityExtension = true
          })
        }
        mountPath = "/etc/kubernetes"
      }
      extraArgs = ["--azure-resource-group=${azurerm_resource_group.dns.name}"]
    })
  ]

  atomic          = true
  cleanup_on_fail = true

  depends_on = [
    azurerm_federated_identity_credential.external_dns,
    azurerm_role_assignment.external_dns_zone_contributor,
    time_sleep.wait_for_kube_admin,
  ]
}
