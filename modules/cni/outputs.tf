output "network_polices_enabled" {
  value       = var.enable_calico_network_polices ? kubernetes_daemon_set_v1.calico[0].id : null
  description = "Denotes if network policies where enabled"
}
