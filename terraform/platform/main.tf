resource "kubernetes_namespace_v1" "sre_lab_tf" {
  metadata {
    name = "sre-lab-tf"

    labels = {
      "app.kubernetes.io/part-of"    = "sre-incident-lab"
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = "lab"
    }
  }
}

resource "kubernetes_resource_quota_v1" "sre_lab_tf" {
  metadata {
    name      = "sre-lab-quota"
    namespace = kubernetes_namespace_v1.sre_lab_tf.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = "500m"
      "requests.memory" = "512Mi"
      "limits.cpu"      = "1"
      "limits.memory"   = "1Gi"
      "pods"            = "5"
    }
  }
}
