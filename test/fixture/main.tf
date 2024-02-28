terraform {
  required_version = ">= 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.38"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.26.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "test" {
  source               = "../../"
  external_dns_support = true
}

provider "kubernetes" {

  host                   = module.test.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.test.eks_cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.test.eks_cluster_name]
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image             = "nginx:latest"
          name              = "nginx"
          image_pull_policy = "Always"

          port {
            container_port = 80
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
        node_selector = {
          "kubernetes.io/os"   = "linux"
          "kubernetes.io/arch" = "amd64"
        }
      }
    }
  }
}
resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.nginx.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type                = "LoadBalancer"
    load_balancer_class = "service.k8s.aws/nlb"
  }
}

resource "kubernetes_deployment" "windows" {
  metadata {
    name      = "windows"
    namespace = "default"
  }

  spec {
    selector {
      match_labels = {
        app = "windows"
      }
    }
    replicas = 1
    template {
      metadata {
        labels = {
          app = "windows"
        }
      }
      spec {
        container {
          image             = "mcr.microsoft.com/windows/servercore/iis:latest"
          name              = "windows"
          image_pull_policy = "Always"
          port {
            name           = "http"
            container_port = 80
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = [
                "NET_RAW",
                "ALL"
              ]
            }
            read_only_root_filesystem = true
          }
        }
        node_selector = {
          "kubernetes.io/os"   = "windows"
          "kubernetes.io/arch" = "amd64"
        }
      }
    }
  }
}

resource "kubernetes_service" "windows" {
  metadata {
    name      = "windows"
    namespace = "default"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.windows.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type                = "LoadBalancer"
    load_balancer_class = "service.k8s.aws/nlb"
  }
}
