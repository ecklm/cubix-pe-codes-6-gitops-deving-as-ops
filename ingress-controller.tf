resource "helm_release" "traefik" {
  provider = helm.sbx

  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = "41.2.0"
  namespace        = "ingress-controller"
  create_namespace = true

  set = [
    {
      name  = "service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
      value = "/healthz"
    },
    {
      name  = "ports.web.http.redirections.entryPoint.to"
      value = "websecure"
    },
    {
      name  = "ports.web.http.redirections.entryPoint.scheme"
      value = "https"
    },
    {
      name  = "ports.web.http.redirections.entryPoint.permanent"
      value = "true"
    }
  ]

  atomic          = true
  cleanup_on_fail = true

  depends_on = [time_sleep.wait_for_kube_admin]
}
