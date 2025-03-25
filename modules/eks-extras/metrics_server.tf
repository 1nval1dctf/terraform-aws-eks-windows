
resource "helm_release" "metrics_server" {
  count      = var.enable_metrics_server ? 1 : var.enable_cluster_autoscaler ? 1 :0
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  namespace  = "kube-system"

  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }
}
