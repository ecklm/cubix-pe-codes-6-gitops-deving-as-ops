resource "helm_release" "demo-app" {
  provider = helm.sbx

  name       = "colors-demo-app"
  repository = "https://bedag.github.io/helm-charts"
  chart      = "raw"
  version    = "2.0.2"
  namespace  = "argocd"

  values = [
    <<-EOT
    ---
    resources:
      - apiVersion: argoproj.io/v1alpha1
        kind: Application
        metadata:
          name: colors
          namespace: argocd
          finalizers:
            - resources-finalizer.argocd.argoproj.io
        spec:
          destination:
            namespace: colors
            server: https://kubernetes.default.svc
          project: product
          syncPolicy:
            syncOptions:
            - CreateNamespace=true
            automated:
              enabled: true
              selfHeal: true
              prune: true
          source:
            path: .
            repoURL: oci://docker.io/ecklm/colors-demo-app
            targetRevision: 1.0.0
            helm:
              valuesObject:
                ingress:
                  host: colors.${local.project_domain}
                  annotations:
                    cert-manager.io/cluster-issuer: letsencrypt
    EOT
  ]

  atomic          = true
  cleanup_on_fail = true

  depends_on = [
    time_sleep.wait_for_kube_admin,
    helm_release.argocd,
    helm_release.argocd-projects
  ]
}
