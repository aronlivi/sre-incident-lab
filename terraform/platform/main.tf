resource "kubernetes_namespace_v1" "sre_lab_tf" {
  metadata {
    name = var.platform_namespace

    labels = {
      "app.kubernetes.io/part-of"    = "sre-incident-lab"
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = "lab"
    }
  }
}

resource "kubernetes_resource_quota_v1" "sre_lab_tf" {
  metadata {
    name      = var.resource_quota_name
    namespace = kubernetes_namespace_v1.sre_lab_tf.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.quota_requests_cpu
      "requests.memory" = var.quota_requests_memory
      "limits.cpu"      = var.quota_limits_cpu
      "limits.memory"   = var.quota_limits_memory
      "pods"            = tostring(var.quota_pods)
    }
  }
}
