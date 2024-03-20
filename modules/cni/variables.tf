variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster name"
}
variable "kubeconfig" {
  type        = string
  description = "EKS KUBECONFIG"
}

variable "enable_calico_network_polices" {
  type        = bool
  description = "Installs and enables calico for netowrk policies"
  default     = true
}

variable "vpc_cni_addon" {
  description = "EKS cluster vpc-cni addon"
}

variable "kube_proxy_addon" {
  description = "EKS cluster kube-proxy addon"
}
