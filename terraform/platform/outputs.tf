output "platform_namespace" {
  description = "Namespace managed by Terraform."
  value       = kubernetes_namespace_v1.sre_lab_tf.metadata[0].name
}

output "resource_quota_name" {
  description = "ResourceQuota managed by Terraform."
  value       = kubernetes_resource_quota_v1.sre_lab_tf.metadata[0].name
}

output "metrics_server_release" {
  description = "Name of the Metrics Server Helm release."
  value       = helm_release.metrics_server.name
}

output "metrics_server_namespace" {
  description = "Namespace containing the Metrics Server Helm release."
  value       = helm_release.metrics_server.namespace
}
