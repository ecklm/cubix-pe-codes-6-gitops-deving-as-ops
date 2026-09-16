apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${certificate_authority_data}
    server: ${server}
  name: ${cluster_name}
contexts:
- context:
    cluster: ${cluster_name}
    user: azure
  name: ${cluster_name}
current-context: ${cluster_name}
users:
- name: azure
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - get-token
      - --login
      - azurecli
      - --server-id
      - 6dae42f8-4368-4678-94ff-3960e28e3630
      command: kubelogin
      env: null
      installHint: |2

        kubelogin is not installed which is required to connect to AAD enabled cluster.

        To learn more, please go to https://aka.ms/aks/kubelogin
      provideClusterInfo: false
