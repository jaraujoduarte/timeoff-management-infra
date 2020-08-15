resource "aws_iam_role" "default_eks" {
  name = "eks-cluster-policy"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "default_eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.default_eks.name
}

resource "aws_eks_cluster" "default" {
  name     = "default"
  role_arn = aws_iam_role.default_eks.arn

  vpc_config {
    subnet_ids = data.aws_subnet_ids.main_private.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.default_eks,
  ]
}

resource "aws_iam_role" "pod_execution" {
  name = "eks-pod-execution"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks-fargate-pods.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "pod_execution" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.pod_execution.name
}

resource "aws_eks_fargate_profile" "default" {
  cluster_name           = aws_eks_cluster.default.name
  fargate_profile_name   = "default"
  pod_execution_role_arn = aws_iam_role.pod_execution.arn
  subnet_ids             = data.aws_subnet_ids.main_private.ids

  selector {
    namespace = "default"
  }
}

resource "aws_eks_fargate_profile" "system" {
  cluster_name           = aws_eks_cluster.default.name
  fargate_profile_name   = "system"
  pod_execution_role_arn = aws_iam_role.pod_execution.arn
  subnet_ids             = data.aws_subnet_ids.main_private.ids

  selector {
    namespace = "kube-system"
  }
}

#data "external" "thumbprint" {
#  program = [
#    "/bin/sh",
#    "${path.module}/externals/thumbprint.sh",
#    data.aws_region.current.name,
#  ]
#}

resource "aws_iam_openid_connect_provider" "default" {
  client_id_list = ["sts.amazonaws.com"]
  # TODO: move to using the external script - get openssl in the Terragrunt image
  #thumbprint_list = [data.external.thumbprint.result.thumbprint]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.default.identity[0].oidc[0].issuer
}
