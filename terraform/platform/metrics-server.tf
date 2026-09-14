resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version
  namespace  = var.metrics_server_namespace

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
