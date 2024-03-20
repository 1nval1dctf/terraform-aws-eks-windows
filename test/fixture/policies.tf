locals {
  network_isolation_name = "no_ingress_egress"
}

resource "kubernetes_network_policy_v1" "no_ingress_egress" {
  metadata {
    name      = "no-ingress-egress"
    namespace = "default"
  }

  spec {
    pod_selector {
      match_labels = {
        networkIsolation = local.network_isolation_name
      }
    }
    policy_types = ["Ingress", "Egress"]
  }
  depends_on = [module.test.network_polices_enabled]
}
