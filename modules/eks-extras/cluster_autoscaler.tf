# policy for cluster-ausoscaler to be able to scale new worker nodes.
locals {
  cluster_autoscaler_sa_name   = "cluster-autoscaler"
  cluster_autoscaler_namespace = "kube-system"
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "cluster_autoscaler" {
  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  count = var.enable_cluster_autoscaler ? 1 : 0
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
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

data "aws_iam_policy_document" "eks_cluster_autoscaler_assume_role" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.selected.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values = [
        "system:serviceaccount:${local.cluster_autoscaler_namespace}:${local.cluster_autoscaler_sa_name}"
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

resource "aws_iam_role" "cluster_autoscaler" {
  count       = var.enable_cluster_autoscaler ? 1 : 0
  name        = local.cluster_autoscaler_sa_name
  description = "Permissions required by cluster_autoscaler to do it's job."


  force_detach_policies = true

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_autoscaler_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = aws_iam_role.cluster_autoscaler[0].name
}

resource "kubernetes_service_account" "cluster_autoscaler" {
  count    = var.enable_cluster_autoscaler ? 1 : 0
  provider = kubernetes
  metadata {
    name      = local.cluster_autoscaler_sa_name
    namespace = local.cluster_autoscaler_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler[0].arn
    }
  }
  automount_service_account_token = "true"
}

resource "kubernetes_cluster_role_binding" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  metadata {
    name = "cluster_autoscaler"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-autoscaler-aws-cluster-autoscaler"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cluster_autoscaler[0].metadata[0].name
    namespace = local.cluster_autoscaler_namespace
  }
}


resource "helm_release" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  name       = "cluster-autoscaler"
  chart      = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  namespace  = local.cluster_autoscaler_namespace

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
    value = data.aws_region.current.region
  }
  set {
    name  = "rbac.create"
    value = "true"
  }
  set {
    name  = "rbac.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "rbac.serviceAccount.name"
    value = local.cluster_autoscaler_sa_name
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
