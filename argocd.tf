locals {
  argocd_name = "${local.resource_basename}-argocd"
  argocd_federated_subjects = {
    argocd_server = "system:serviceaccount:argocd:argocd-server"
  }
}

resource "azuread_application" "argocd" {
  display_name                   = local.argocd_name
  sign_in_audience               = "AzureADMyOrg"
  group_membership_claims        = ["SecurityGroup"]
  fallback_public_client_enabled = true

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read (delegated)
      type = "Scope"
    }
  }

  web {
    redirect_uris = [
      "https://argocd.${local.project_domain}/auth/callback",
    ]
  }

  public_client {
    redirect_uris = [
      "https://localhost:8085/auth/callback",
    ]
  }
}

resource "azuread_service_principal" "argocd" {
  client_id                    = azuread_application.argocd.client_id
  app_role_assignment_required = false
  login_url                    = "https://argocd.${local.project_domain}/"

  feature_tags {
    enterprise = true
    gallery    = false
  }
}

resource "azuread_application_federated_identity_credential" "argocd" {
  for_each = local.argocd_federated_subjects

  application_id = azuread_application.argocd.id
  display_name   = "argocd-${each.key}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject        = each.value

  depends_on = [azuread_service_principal.argocd]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.1.1"
  namespace        = "argocd"
  create_namespace = true

  values = concat(
    [
      <<EOT
      configs:
        cm:
          oidc.config: |
            name: Azure
            issuer: https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0
            clientID: ${azuread_application.argocd.client_id}
            azure:
              useWorkloadIdentity: true
            requestedIDTokenClaims:
              groups:
                essential: true
            requestedScopes:
              - openid
              - profile
              - email
        params:
          server.insecure: true
        rbac:
          policy.csv: |
            g, ${azuread_group.platform_admins.object_id}, role:admin
          scopes: '[groups, roles, email]'
      repoServer:
        podLabels:
          azure.workload.identity/use: "true"
        serviceAccount:
          annotations:
            azure.workload.identity/client-id: "${azuread_application.argocd.client_id}"
      server:
        podLabels:
          azure.workload.identity/use: "true"
        serviceAccount:
          annotations:
            azure.workload.identity/client-id: "${azuread_application.argocd.client_id}"
        ingress:
          enabled: true
          tls: true
          annotations:
            cert-manager.io/cluster-issuer: letsencrypt
      global:
        domain: argocd.${local.project_domain}
      EOT
    ]
  )

  depends_on = [
    time_sleep.wait_for_kube_admin,
    azuread_application_federated_identity_credential.argocd,
    azuread_group_member.platform_admin_members,
  ]
}
