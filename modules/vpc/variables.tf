variable "eks_cluster_name" {
  type        = string
  default     = "eks"
  description = "Name of the eks cluster. Needed for subnet tags"
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
