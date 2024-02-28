variable "eks_cluster_name" {
  type        = string
  default     = "eks"
  description = "Name for the EKS Cluster"
}

variable "aws_region" {
  type        = string
  description = "Region to deploy EKS Cluster into"
  default     = "us-east-1"
}

variable "eks_cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
  default     = "1.29"
}

variable "eks_users" {
  description = "Additional AWS users to add to the EKS aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}

# EKS autoscaling
variable "eks_autoscaling_group_linux_min_size" {
  description = "Minimum number of Linux nodes for the EKS."
  default     = 1
  type        = number
}

variable "eks_autoscaling_group_linux_desired_capacity" {
  description = "Desired capacity for Linux nodes for the EKS."
  default     = 1
  type        = number
}

variable "eks_autoscaling_group_linux_max_size" {
  description = "Minimum number of Linux nodes for the EKS."
  default     = 2
  type        = number
}

variable "eks_linux_instance_type" {
  description = "Instance size for EKS worker nodes."
  default     = "m5.large"
  type        = string
}

# EKS autoscaling for windows
variable "eks_autoscaling_group_windows_min_size" {
  description = "Minimum number of Windows nodes for the EKS"
  default     = 1
  type        = number
}

variable "eks_autoscaling_group_windows_desired_capacity" {
  description = "Desired capacity for Windows nodes for the EKS."
  default     = 1
  type        = number
}

variable "eks_autoscaling_group_windows_max_size" {
  description = "Maximum number of Windows nodes for the EKS."
  default     = 2
  type        = number
}

variable "eks_windows_instance_type" {
  description = "Instance size for EKS windows worker nodes."
  default     = "m5.large"
  type        = string
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

variable "windows_ami_type" {
  description = "AMI type for the Windows Nodes."
  default     = "WINDOWS_CORE_2022_x86_64"
  type        = string
}
