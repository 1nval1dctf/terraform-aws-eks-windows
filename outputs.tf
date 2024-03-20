output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Id for the VPC created for CTFd"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "List of private subnets that contain backend infrastructure (RDS, ElastiCache, EC2)"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "List of public subnets that contain frontend infrastructure (ALB)"
}


output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster ID"
  depends_on = [
    module.eks_extras
  ]
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster endpoint"
  depends_on = [
    module.eks_extras
  ]
}
output "eks_cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "EKS cluster CA"
  depends_on = [
    module.eks_extras
  ]
}

output "kubeconfig" {
  value       = module.eks.kubeconfig
  description = "kubeconfig for the AWS EKS cluster"
}

output "load_balancer_controller_helm_release_version" {
  description = "Load Balancer controller helm release version. Depend on this in your kubernetes deployments if you use services with load balacers and want to be able to destroy from a single terraform deploymemt"
  value       = module.eks_extras.load_balancer_controller_helm_release_version
}
