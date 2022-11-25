locals {
  eks_common_tags = {
    service = "AWS/EKS"
  }
}

category "aws_eks_addon" {
  title = "EKS Addon"
  color = local.containers_color
  icon  = "text:Addon"
}

category "aws_eks_cluster" {
  title = "EKS Cluster"
  color = local.containers_color
  href  = "/aws_insights.dashboard.aws_eks_cluster_detail?input.eks_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "cog"
}

category "aws_eks_fargate_profile" {
  title = "EKS Farget Profile"
  color = local.containers_color
  icon  = "FP"
}

category "aws_eks_identity_provider_config" {
  title = "EKS Identity Provider Config"
  color = local.containers_color
  icon  = "text:IPC"
}

category "aws_eks_node_group" {
  title = "EKS Node Group"
  color = local.containers_color
  icon  = "rectangle-group"
}
