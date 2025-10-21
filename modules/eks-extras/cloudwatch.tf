
# policy for cloudwatch_exporter to be able to get metrics.
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "cloudwatch_exporter" {
  count = var.enable_cloudwatch_exported ? 1 : 0
  statement {
    actions = [
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "tag:GetResources"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "cloudwatch_exporter" {
  count  = var.enable_cloudwatch_exported ? 1 : 0
  name   = "cloudwatch_exporter"
  path   = "/"
  policy = data.aws_iam_policy_document.cloudwatch_exporter[0].json
}

resource "aws_iam_role_policy_attachment" "linux_node_group_metrics" {
  count      = var.enable_cloudwatch_exported ? 1 : 0
  policy_arn = aws_iam_policy.cloudwatch_exporter[0].arn
  role       = var.linux_node_group_iam_role
}

resource "aws_iam_role_policy_attachment" "windows_node_group_metrics" {
  count      = var.enable_cloudwatch_exported ? 1 : 0
  policy_arn = aws_iam_policy.cloudwatch_exporter[0].arn
  role       = var.windows_node_group_iam_role
}

resource "kubernetes_namespace" "fluent_bit" {
  count = var.enable_cloudwatch_exported ? 1 : 0
  metadata {
    name = local.fluent_bit_namespace
  }
}

data "aws_region" "current" {}

resource "helm_release" "fluent_bit_daemonset" {
  count      = var.enable_cloudwatch_exported ? 1 : 0
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"

  name      = "fluent-bit"
  namespace = kubernetes_namespace.fluent_bit[0].metadata[0].name

  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }
  set {
    name  = "nodeSelector.kubernetes\\.io/arch"
    value = "x64"
  }
  set {
    name  = "config.outputs"
    value = templatefile("${path.module}/templates/output.conf", { aws_region = data.aws_region.current.region })
  }
  set {
    name  = "config.parsers"
    value = file("${path.module}/templates/parsers.conf")
  }
  set {
    name  = "config.customParsers"
    value = file("${path.module}/templates/filters.conf")
  }
}
