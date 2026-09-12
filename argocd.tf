resource "helm_release" "argocd" {
  provider = helm.sbx

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
        params:
          server.insecure: true
      server:
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

  depends_on = [time_sleep.wait_for_kube_admin]
}
