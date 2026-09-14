variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used by Terraform providers."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context used by the Kubernetes and Helm providers."
  type        = string
  default     = "kind-sre-lab"
}

variable "platform_namespace" {
  description = "Namespace managed by Terraform for platform validation."
  type        = string
  default     = "sre-lab-tf"
}

variable "resource_quota_name" {
  description = "Name of the ResourceQuota created in the platform namespace."
  type        = string
  default     = "sre-lab-quota"
}

variable "quota_requests_cpu" {
  description = "Maximum total requested CPU allowed in the platform namespace."
  type        = string
  default     = "500m"
}

variable "quota_requests_memory" {
  description = "Maximum total requested memory allowed in the platform namespace."
  type        = string
  default     = "512Mi"
}

variable "quota_limits_cpu" {
  description = "Maximum total CPU limits allowed in the platform namespace."
  type        = string
  default     = "1"
}

variable "quota_limits_memory" {
  description = "Maximum total memory limits allowed in the platform namespace."
  type        = string
  default     = "1Gi"
}

variable "quota_pods" {
  description = "Maximum number of Pods allowed in the platform namespace."
  type        = number
  default     = 5
}

variable "metrics_server_chart_version" {
  description = "Helm chart version used to install Metrics Server."
  type        = string
  default     = "3.14.0"
}

variable "metrics_server_namespace" {
  description = "Namespace where the Metrics Server Helm release is installed."
  type        = string
  default     = "kube-system"
}
