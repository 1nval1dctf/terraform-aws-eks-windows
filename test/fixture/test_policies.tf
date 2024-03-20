resource "kubernetes_deployment" "windows_netpol_test" {
  metadata {
    name = "windows-netpol-test"
    labels = {
      app              = "windows-netpol-test"
      networkIsolation = local.network_isolation_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app              = "windows-netpol-test"
        networkIsolation = local.network_isolation_name
      }
    }
    template {
      metadata {
        name = "windows-netpol-test"
        labels = {
          app              = "windows-netpol-test"
          networkIsolation = local.network_isolation_name
        }
      }
      spec {
        container {
          image = "mcr.microsoft.com/windows/servercore:ltsc2022"
          name  = "windows-netpol-test"
          command = [
            "powershell",
            "-Command",
            "while ($true) {start-sleep -seconds 1}"
          ]

          liveness_probe {
            exec {
              command = [
                "powershell",
                "-Command",
                "'!(ping -n 2 8.8.8.8) -and !(invoke-webrequest -Uri 169.254.169.254 -UseBasicParsing -TimeoutSec 4)'"
              ]
            }
            failure_threshold = 1

            initial_delay_seconds = 5
            period_seconds        = 20
            timeout_seconds       = 15
          }
        }
        node_selector = {
          "kubernetes.io/os" = "windows"
        }
      }
    }
  }
  depends_on = [kubernetes_network_policy_v1.no_ingress_egress]
}

resource "kubernetes_deployment" "linux_netpol_test" {
  metadata {
    name = "linux-netpol-test"
    labels = {
      app              = "linux-netpol-test"
      networkIsolation = local.network_isolation_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app              = "linux-netpol-test"
        networkIsolation = local.network_isolation_name
      }
    }
    template {
      metadata {
        name = "linux-netpol-test"
        labels = {
          app              = "linux-netpol-test"
          networkIsolation = local.network_isolation_name
        }
      }
      spec {
        container {
          image = "nicolaka/netshoot"
          name  = "linux-netpol-test"
          command = [
            "sleep",
            "infinity"
          ]
          liveness_probe {
            exec {
              command = [
                "sh",
                "-c",
                "! curl --max-time 4 169.254.169.254"
              ]
            }
            failure_threshold = 1

            initial_delay_seconds = 50
            period_seconds        = 30
            timeout_seconds       = 10
          }
          security_context {
            capabilities {
              add  = ["NET_RAW"]
              drop = ["ALL"]
            }
          }
        }
        node_selector = {
          "kubernetes.io/os" = "linux"
        }
      }
    }
  }
  depends_on = [kubernetes_network_policy_v1.no_ingress_egress]
}
