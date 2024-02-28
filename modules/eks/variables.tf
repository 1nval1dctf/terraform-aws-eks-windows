variable "vpc_id" {
  type        = string
  description = "Id for the VPC for CTFd"
  default     = null
}

variable "aws_region" {
  type        = string
  description = "Region to deploy EKS Cluster into"
  default     = "us-east-1"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids"
  default     = []
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet ids"
  default     = []
}

variable "eks_cluster_name" {
  type        = string
  description = "Name for the EKS cluster"
  default     = "eks"
}
variable "eks_cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
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

# eks autoscaling
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

# eks autoscaling for windows
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
  description = "Instance size for EKS worker nodes."
  default     = "m5.large"
  type        = string
}

variable "windows_ami_type" {
  description = "AMI type for the Windows Nodes."
  type        = string
}
