output "load_balancer_controller_helm_release_version" {
  description = "Load Balancer controller helm release version"
  value       = var.enable_loadbalancer_controler ? helm_release.aws_lb[0].metadata[0].version : ""
}
