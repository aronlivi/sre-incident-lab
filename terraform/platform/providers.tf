provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = "kind-sre-lab"
}

provider "helm" {
  kubernetes = {
    config_path    = pathexpand("~/.kube/config")
    config_context = "kind-sre-lab"
  }
}
