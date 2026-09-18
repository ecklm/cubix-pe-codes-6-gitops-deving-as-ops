resource "helm_release" "cert_manager" {
  provider = helm.sbx

  name             = "cert-manager"
  repository       = "https://bedag.github.io/helm-charts"
  chart            = "raw"
  version          = "2.0.2"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    <<-EOT
    ---
    resources:
      - apiVersion: argoproj.io/v1alpha1
        kind: Application
        metadata:
          name: cert-manager
          namespace: argocd
          finalizers:
            - resources-finalizer.argocd.argoproj.io
        spec:
          destination:
            namespace: cert-manager
            server: https://kubernetes.default.svc
          project: platform
          ignoreDifferences:
            - group: admissionregistration.k8s.io
              kind: ValidatingWebhookConfiguration
              name: cert-manager-webhook
              jsonPointers:
                - /webhooks/0/namespaceSelector/matchExpressions
            - group: admissionregistration.k8s.io
              kind: MutatingWebhookConfiguration
              name: cert-manager-webhook
              jsonPointers:
                - /webhooks/0/namespaceSelector/matchExpressions
          syncPolicy:
            syncOptions:
            - CreateNamespace=true
            automated:
              enabled: true
              selfHeal: true
              prune: true
          source:
            chart: cert-manager
            repoURL: https://charts.jetstack.io
            targetRevision: v1.19.4
            helm:
              valuesObject:
                crds:
                  enabled: true
                prometheus:
                  enabled: false
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

resource "helm_release" "letsencrypt_cluster_issuer" {
  provider = helm.sbx

  name             = "letsencrypt-cluster-issuer"
  repository       = "https://bedag.github.io/helm-charts"
  chart            = "raw"
  version          = "2.0.2"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    <<-EOT
    ---
    resources:
      - apiVersion: argoproj.io/v1alpha1
        kind: Application
        metadata:
          name: letsencrypt-cluster-issuer
          namespace: argocd
          finalizers:
            - resources-finalizer.argocd.argoproj.io
        spec:
          destination:
            namespace: cert-manager
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
            chart: raw
            repoURL: https://bedag.github.io/helm-charts
            targetRevision: 2.0.2
            helm:
              valuesObject:
                resources:
                  - apiVersion: cert-manager.io/v1
                    kind: ClusterIssuer
                    metadata:
                      name: letsencrypt
                    spec:
                      acme:
                        email: ecklm@cubix-pe.hu
                        server: https://acme-v02.api.letsencrypt.org/directory
                        privateKeySecretRef:
                          name: letsencrypt-account-key
                        solvers:
                          - http01:
                              ingress: {}
    EOT
  ]

  atomic          = true
  cleanup_on_fail = true

  depends_on = [helm_release.cert_manager]
}
