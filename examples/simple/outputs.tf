
output "kubeconfig" {
  value       = module.eks_windows.kubeconfig
  description = "kubeconfig for the AWS EKS cluster"
}
