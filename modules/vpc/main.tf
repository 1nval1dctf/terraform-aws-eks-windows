terraform {
  required_version = ">= 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.38"
    }
  }
}

# Grab the list of availability zones
data "aws_availability_zones" "available" {}

# Create a VPC to launch our instances into
module "vpc" {
  source                               = "terraform-aws-modules/vpc/aws"
  version                              = "5.5.2"
  name                                 = "${var.eks_cluster_name}-vpc"
  cidr                                 = var.vpc_cidr_block
  azs                                  = data.aws_availability_zones.available.names
  private_subnets                      = var.vpc_cidr_private_subnets
  public_subnets                       = var.vpc_cidr_public_subnets
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_nat_gateway                   = true
  single_nat_gateway                   = true
  map_public_ip_on_launch              = true
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
