resource "helm_release" "cert_manager" {
  provider = helm.sbx

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.19.4"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    yamlencode({
      crds = {
        enabled = true
      }
      prometheus = {
        enabled = false
      }
    })
  ]

  atomic          = true
  cleanup_on_fail = true

  depends_on = [time_sleep.wait_for_kube_admin]
}

resource "helm_release" "letsencrypt_cluster_issuer" {
  provider = helm.sbx

  name       = "letsencrypt-cluster-issuer"
  repository = "https://bedag.github.io/helm-charts"
  chart      = "raw"
  version    = "2.0.2"
  namespace  = "cert-manager"

  values = [
    yamlencode({
      resources = [
        {
          apiVersion = "cert-manager.io/v1"
          kind       = "ClusterIssuer"
          metadata = {
            name = "letsencrypt"
          }
          spec = {
            acme = {
              email  = "ecklm@ecklm.com"
              server = "https://acme-v02.api.letsencrypt.org/directory"
              privateKeySecretRef = {
                name = "letsencrypt-account-key"
              }
              solvers = [
                {
                  http01 = {
                    ingress = {}
                  }
                }
              ]
            }
          }
        }
      ]
    })
  ]

  atomic          = true
  cleanup_on_fail = true

  depends_on = [helm_release.cert_manager]
}
