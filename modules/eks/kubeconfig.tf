
locals {
  kubeconfig = yamlencode({
    apiVersion = "v1"
    clusters = [{
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
      name = module.eks.cluster_arn
    }]
    contexts = [{
      name = module.eks.cluster_arn
      context = {
        cluster = module.eks.cluster_arn
        user    = module.eks.cluster_arn
      }
    }]
    current-context = module.eks.cluster_arn
    preferences     = {}
    kind            = "Config"
    users = [{
      name = module.eks.cluster_arn
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          args = [
            "--region",
            var.aws_region,
            "eks",
            "get-token",
            "--cluster-name",
            module.eks.cluster_name,
          ]
          command = "aws"
        }
      }
    }]
  })
}
