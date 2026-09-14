resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.14.0"
  namespace  = "kube-system"

  wait    = true
  timeout = 180

  values = [
    yamlencode({
      args = [
        "--kubelet-insecure-tls"
      ]
    })
  ]
}
