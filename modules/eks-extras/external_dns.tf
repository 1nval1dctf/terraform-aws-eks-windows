# policy for external-dns to be able to set records.
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "route53_change_records" {
  count = var.external_dns_support ? 1 : 0
  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/*"
    ]
  }
  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "route53_change_records" {
  count  = var.external_dns_support ? 1 : 0
  name   = "route53_change_records"
  path   = "/"
  policy = data.aws_iam_policy_document.route53_change_records[0].json
}

resource "aws_iam_role_policy_attachment" "linux_node_group_dns" {
  count      = var.external_dns_support ? 1 : 0
  policy_arn = aws_iam_policy.route53_change_records[0].arn
  role       = var.linux_node_group_iam_role
}

resource "aws_iam_role_policy_attachment" "windows_node_group_dns" {
  count      = var.external_dns_support ? var.windows_support ? 1 : 0 : 0
  policy_arn = aws_iam_policy.route53_change_records[0].arn
  role       = var.windows_node_group_iam_role
}

#tfsec:ignore:GEN003
resource "kubernetes_service_account_v1" "external_dns" {
  count    = var.external_dns_support ? 1 : 0
  provider = kubernetes
  metadata {
    name = "external-dns"
  }
  automount_service_account_token = "true"
}
resource "kubernetes_cluster_role" "external_dns" {
  count = var.external_dns_support ? 1 : 0
  metadata {
    name = "external-dns"
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses/status"]
    verbs      = ["patch", "update"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "external_dns" {
  count = var.external_dns_support ? 1 : 0
  metadata {
    name = "external-dns-viewer"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "external-dns"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "external-dns"
    namespace = "default"
  }
}
