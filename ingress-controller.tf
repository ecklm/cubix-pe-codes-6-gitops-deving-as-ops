resource "helm_release" "traefik" {
  provider = helm.sbx

  name             = "traefik"
  repository       = "https://bedag.github.io/helm-charts"
  chart            = "raw"
  version          = "2.0.2"
  namespace        = "ingress-controller"
  create_namespace = true

  values = [
    <<-EOT
    ---
    resources:
      - apiVersion: argoproj.io/v1alpha1
        kind: Application
        metadata:
          name: traefik
          namespace: argocd
          finalizers:
            - resources-finalizer.argocd.argoproj.io
        spec:
          destination:
            namespace: ingress-controller
            server: https://kubernetes.default.svc
          project: platform
          syncPolicy:
            syncOptions:
            - CreateNamespace=true
            automated:
              enabled: true
              selfHeal: true
              prune: true
          source:
            chart: traefik
            repoURL: https://traefik.github.io/charts
            targetRevision: 41.2.0
            helm:
              valuesObject:
                service:
                  annotations:
                    service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
                ports:
                  web:
                    http:
                      redirections:
                        entryPoint:
                          to: websecure
                          scheme: https
                          permanent: true
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
