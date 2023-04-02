variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster name"
}

variable "linux_node_group_iam_role" {
  type        = string
  description = "IAM role arn for Linux managed node group"
  default     = null
}

variable "windows_node_group_iam_role" {
  type        = string
  description = "IAM role arn for windows managed node group"
  default     = null
}

variable "external_dns_support" {
  type        = bool
  description = "Setup IAM, service accoutn and cluster role for external_dns in EKS"
  default     = false
}

variable "enable_metrics_server" {
  type        = bool
  description = "Install metrics server into the cluster"
  default     = true
}

variable "enable_cluster_autoscaler" {
  type        = bool
  description = "Enable cluster autoscaler"
  default     = true
}

variable "enable_cloudwatch_exported" {
  type        = bool
  description = "Enable cloudwatch exporter"
  default     = true
}

variable "enable_loadbalancer_controler" {
  type        = bool
  description = "Enable ALB load Balancer controller"
  default     = true
}
