# policy for cluster-ausoscaler to be able to scale new worker nodes.

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "cluster_autoscaler" {
  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  count = var.enable_cluster_autoscaler ? 1 : 0
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeAutoScalingGroups",
      "ec2:DescribeLaunchTemplateVersions",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeLaunchConfigurations",
      "ec2:DescribeInstanceTypes",
      "autoscaling:DescribeScalingActivities"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count       = var.enable_cluster_autoscaler ? 1 : 0
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${var.eks_cluster_name}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler[0].json
}

resource "aws_iam_role_policy_attachment" "linux_node_group_cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = var.linux_node_group_iam_role
}

resource "aws_iam_role_policy_attachment" "windows_node_group_cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = var.windows_node_group_iam_role
}


resource "helm_release" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  name       = "cluster-autoscaler"
  chart      = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  namespace  = "kube-system"

  set {
    name  = "image.tag"
    value = "v1.26.2"
  }
  set {
    name  = "image.pullPolicy"
    value = "Always"
  }
  set {
    name  = "autoDiscovery.enabled"
    value = "true"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = var.eks_cluster_name
  }
  set {
    name  = "cloudProvider"
    value = "aws"
  }
  set {
    name  = "awsRegion"
    value = data.aws_region.current.name
  }
  set {
    name  = "rbac.create"
    value = "true"
  }
  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }
  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = "false"
  }
  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }
  set {
    name  = "extraArgs.expander"
    value = "least-waste"
  }
  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }
}
