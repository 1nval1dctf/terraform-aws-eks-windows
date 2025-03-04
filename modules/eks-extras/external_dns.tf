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
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
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

resource "aws_iam_role_policy_attachment" "external_dns" {
  count      = var.external_dns_support ? 1 : 0
  policy_arn = aws_iam_policy.route53_change_records[0].arn
  role       = aws_iam_role.external_dns[0].name
}

data "aws_caller_identity" "current" {}
data "aws_eks_cluster" "selected" {
  name = var.eks_cluster_name
}
data "aws_iam_policy_document" "eks_oidc_assume_role" {
  count = var.external_dns_support ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.selected.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values = [
        "system:serviceaccount:default:external-dns"
      ]
    }
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.selected.identity[0].oidc[0].issuer, "https://", "")}"
      ]
      type = "Federated"
    }
  }
}

resource "aws_iam_role" "external_dns" {
  count       = var.external_dns_support ? 1 : 0
  name        = "external-dns"
  description = "Permissions required by external-dns to do it's job."


  force_detach_policies = true

  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role[0].json
}
#tfsec:ignore:GEN003
resource "kubernetes_service_account" "external_dns" {
  count    = var.external_dns_support ? 1 : 0
  provider = kubernetes
  metadata {
    name = "external-dns"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns[0].arn
    }
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
    name      = kubernetes_service_account.external_dns[0].metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_dns[0].metadata[0].name
    namespace = "default"
  }
}
