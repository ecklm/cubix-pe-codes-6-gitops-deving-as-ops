terraform {
  required_version = ">= 1.4"

  backend "azurerm" {
    use_cli              = true
    use_azuread_auth     = true
    storage_account_name = "platencbecklm"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.1"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "fba39c62-2b48-482e-8377-d811aa355544"
  tenant_id       = "8820d9af-b533-4848-9bf3-ebf24d29d140"
}

provider "azuread" {
  tenant_id = "8820d9af-b533-4848-9bf3-ebf24d29d140"
}

provider "helm" {
  kubernetes = {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args = [
        "get-token",
        "--login",
        "azurecli",
        "--server-id",
        "6dae42f8-4368-4678-94ff-3960e28e3630", # Azure public cloud
      ]
    }
  }
}
