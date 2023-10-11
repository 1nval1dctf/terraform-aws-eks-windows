terraform {
  required_version = ">= 1.4.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.60.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "eks_windows" {
  source = "git::https://github.com/chtbks/devops-terraform-aws-eks-windows?ref=v1.0.0"
}
