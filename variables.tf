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
  default     = "1.26"
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
  description = "Instance size for EKS linux worker nodes."
  default     = "m5.large"
  type        = string
}

variable "eks_windows_instance_type" {
  description = "Instance size for EKS windows worker nodes."
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

variable "eks_windows_disk_size" {
  description = "Disk size of the windows nodes"
  default     = 150
  type        = number
}

variable "external_dns_support" {
  type        = bool
  description = "Setup IAM, service accounts and cluster role for external_dns in EKS"
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

variable "vpc_cidr_block" {
  type        = string
  description = "The top-level CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "vpc_cidr_private_subnets" {
  type        = list(string)
  description = "private subnets in the main CIDR block for the VPC."
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "vpc_cidr_public_subnets" {
  type        = list(string)
  description = "private subnets in the main CIDR block for the VPC."
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "eks_windows_key_pair_name" {
  type        = string
  description = "security key pair to apply to the windows nodes"
}
