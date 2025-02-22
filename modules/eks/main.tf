terraform {
  required_version = ">= 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88"
    }
  }
}
locals {
  linux = {
    # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
    # so we need to disable it to use the default template provided by the AWS EKS managed node group service
    use_custom_launch_template = false
    tags = {
      "k8s.io/cluster-autoscaler/enabled"                 = "true",
      "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
    }

    instance_types = [var.eks_linux_instance_type]
    min_size       = var.eks_autoscaling_group_linux_min_size
    max_size       = var.eks_autoscaling_group_linux_max_size
    desired_size   = var.eks_autoscaling_group_linux_desired_capacity
  }
  windows = {
    # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
    # so we need to disable it to use the default template provided by the AWS EKS managed node group service
    use_custom_launch_template = false
    ami_type                   = var.windows_ami_type
    tags = {
      "k8s.io/cluster-autoscaler/enabled"                 = "true",
      "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
    }
    instance_types = [var.eks_windows_instance_type]
    min_size       = var.eks_autoscaling_group_windows_min_size
    max_size       = var.eks_autoscaling_group_windows_max_size
    desired_size   = var.eks_autoscaling_group_windows_desired_capacity
  }
  eks_managed_node_groups_linux = {
    linux = local.linux
  }
  eks_managed_node_groups_both = {
    linux   = local.linux
    windows = local.windows
  }
  eks_managed_node_groups = [local.eks_managed_node_groups_both, local.eks_managed_node_groups_linux][var.eks_autoscaling_group_windows_max_size > 0 ? 0 : 1]
}
module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "20.33.1"
  cluster_name                   = var.eks_cluster_name
  cluster_version                = var.eks_cluster_version
  subnet_ids                     = concat(var.private_subnet_ids, var.public_subnet_ids)
  vpc_id                         = var.vpc_id
  cluster_endpoint_public_access = true

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true
  eks_managed_node_groups                  = local.eks_managed_node_groups
  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
  }
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}
resource "aws_eks_access_entry" "user_access" {
  for_each = {
    for index, user in var.eks_users :
    user.username => user
  }
  cluster_name      = module.eks.cluster_name
  principal_arn     = each.value.userarn
  kubernetes_groups = each.value.groups
  type              = "STANDARD"
  user_name         = each.value.username
}

resource "aws_eks_access_policy_association" "user_access_policy_association" {

  for_each = {
    for index, user in var.eks_users :
    user.username => user
  }
  access_scope {
    type = "cluster"
  }

  cluster_name = module.eks.cluster_name

  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value.userarn

  depends_on = [
    aws_eks_access_entry.user_access,
  ]
}
