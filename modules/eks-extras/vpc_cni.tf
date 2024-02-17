
# eks is spun up with aws-vpc-cni helm chart regardless if it is specified in cluster_addons
# this config can't be set from terraform that I can see. The best option is to overwrite
# the existing configmap with the settings we need.
resource "kubernetes_config_map_v1_data" "amazon_vpc_cni" {
  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }
  data = {
    enable-windows-ipam              = true
    enable-network-policy-controller = true
  }
  force = true
}
