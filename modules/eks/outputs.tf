output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster ID"
}
output "cluster_arn" {
  value       = module.eks.cluster_arn
  description = "EKS cluster arn"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster endpoint"
}
output "cluster_oicd_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "EKS OICD Provider arn"
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "EKS cluster CA"
}

output "linux_node_group_iam_role" {
  description = "IAM role name for linux EKS managed node group"
  value       = module.eks.eks_managed_node_groups["linux"].iam_role_name
}

output "windows_node_group_iam_role" {
  description = "IAM role name for windows EKS managed node group"
  value       = module.eks.eks_managed_node_groups["windows"].iam_role_name
}

output "kubeconfig" {
  value       = local.kubeconfig
  description = "kubeconfig for the AWS EKS cluster"
}

output "kube_proxy_addon" {
  value       = lookup(module.eks.cluster_addons, "kube-proxy")
  description = "Attribute maps for  EKS cluster kube_proxy addon"
}

output "coredns_addon" {
  value       = lookup(module.eks.cluster_addons, "coredns")
  description = "Attribute maps for  EKS cluster coreDNS addon"
}

output "vpc_cni_addon" {
  value       = lookup(module.eks.cluster_addons, "vpc-cni")
  description = "Attribute maps for  EKS cluster VPC CNI addon"
}
