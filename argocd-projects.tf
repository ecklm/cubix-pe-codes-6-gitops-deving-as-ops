locals {
  argocd_projects = toset([
    "product",
    "platform"
  ])
}

resource "helm_release" "argocd-projects" {
  provider = helm.sbx
  for_each = local.argocd_projects # Just to avoid code duplication

  name       = "argocd-project-${each.key}"
  repository = "https://bedag.github.io/helm-charts"
  chart      = "raw"
  version    = "2.0.2"
  namespace  = "argocd"

  values = [
    <<-EOT
    ---
    resources:
      - apiVersion: argoproj.io/v1alpha1
        kind: AppProject
        metadata:
          generation: 4
          name: ${each.key}
          namespace: argocd
        spec:
          clusterResourceWhitelist:
          - group: '*'
            kind: '*'
          destinations:
          - name: '*'
            namespace: '*'
            server: '*'
          namespaceResourceWhitelist:
          - group: '*'
            kind: '*'
          sourceRepos:
          - '*'
    EOT
  ]

  atomic          = true
  cleanup_on_fail = true

  depends_on = [
    time_sleep.wait_for_kube_admin,
    helm_release.argocd
  ]
}
