terraform {
  required_version = ">= 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.37.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "eks_windows" {
  source = "../../" # Actually set to "1nval1dctf/eks-windows/aws"
}
