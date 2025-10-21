terraform {
  required_version = ">= 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.1"
    }
  }
}

locals {
  kubeconfig_filename = "${path.module}/.kubeconfig"
  kube_proxy_version  = split("-", var.kube_proxy_addon.addon_version)[0]
}

data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

resource "local_file" "kube_config" {
  content  = var.kubeconfig
  filename = local.kubeconfig_filename
}
# eks is spun up with aws-vpc-cni helm chart regardless if it is specified in cluster_addons
# this config can't be set from terraform that I can see. The best option is to overwrite
# # the existing configmap with the settings we need.
resource "kubernetes_config_map_v1_data" "amazon_vpc_cni" {
  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }
  data = {
    enable-windows-ipam = true
  }
  force = true
  depends_on = [
    var.vpc_cni_addon
  ]
}

# Following https://docs.tigera.io/calico/latest/getting-started/kubernetes/windows-calico/operator
resource "kubernetes_config_map_v1" "kubernetes_services_endpoint" {
  count = var.enable_calico_network_polices ? 1 : 0
  metadata {
    name      = "kubernetes-services-endpoint"
    namespace = "tigera-operator"
  }
  data = {
    KUBERNETES_SERVICE_HOST : replace(data.aws_eks_cluster.eks.endpoint, "https://", "")
    KUBERNETES_SERVICE_PORT : 443
  }
  depends_on = [kubernetes_config_map_v1_data.amazon_vpc_cni]
}
resource "kubernetes_namespace_v1" "calico" {
  count = var.enable_calico_network_polices ? 1 : 0
  metadata {
    name = "tigera-operator"
  }
}


resource "helm_release" "calico" {
  count      = var.enable_calico_network_polices ? 1 : 0
  repository = "https://docs.tigera.io/calico/charts"
  chart      = "tigera-operator"
  name       = "calico"
  namespace  = kubernetes_namespace_v1.calico[0].metadata[0].name
  version    = "3.28.1"

  set {
    name  = "installation.kubernetesProvider"
    value = "EKS"
  }
  depends_on = [kubernetes_config_map_v1.kubernetes_services_endpoint[0]
  ]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    kubectl patch installation default --type merge --patch='{"spec": {"serviceCIDRs": ["${data.aws_eks_cluster.eks.kubernetes_network_config[0].service_ipv4_cidr}"], "calicoNetwork": {"windowsDataplane": "HNS"}}}'  --kubeconfig ${local_file.kube_config.filename}
    EOT
    on_failure  = continue
  }
}

resource "kubernetes_daemon_set_v1" "calico" {
  count = var.enable_calico_network_polices ? 1 : 0
  metadata {
    name      = "kube-proxy-windows"
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-proxy"
    }
  }
  spec {
    selector {
      match_labels = {
        k8s-app = "kube-proxy-windows"
      }
    }
    template {
      metadata {
        labels = {
          k8s-app : "kube-proxy-windows"
        }
      }
      spec {
        service_account_name = "kube-proxy"
        security_context {
          windows_options {
            host_process              = true
            run_as_username           = "NT AUTHORITY\\system"
            gmsa_credential_spec      = "null"
            gmsa_credential_spec_name = "null"
          }
        }
        host_network = true
        container {
          image             = "sigwindowstools/kube-proxy:${local.kube_proxy_version}-calico-hostprocess"
          args              = ["$env:CONTAINER_SANDBOX_MOUNT_POINT/kube-proxy/start.ps1"]
          working_dir       = "$env:CONTAINER_SANDBOX_MOUNT_POINT/kube-proxy/"
          name              = "kube-proxy"
          image_pull_policy = "Always"
          env {
            name = "NODENAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "spec.nodeName"
              }
            }
          }
          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }
          volume_mount {
            mount_path = "/var/lib/kube-proxy"
            name       = "kube-proxy"
          }
        }
        node_selector = {
          "kubernetes.io/os" = "windows"
        }
        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }
        volume {
          config_map {
            name = "kube-proxy"
          }
          name = "kube-proxy"
        }
      }
    }
    strategy {
      type = "RollingUpdate"
    }
  }
  depends_on = [helm_release.calico[0]]
}
