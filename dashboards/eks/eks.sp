locals {
  eks_common_tags = {
    service = "AWS/EKS"
  }
}

category "eks_addon" {
  title = "EKS Addon"
  color = local.containers_color
  icon  = "extension"
}

category "eks_cluster" {
  title = "EKS Cluster"
  color = local.containers_color
  href  = "/aws_insights.dashboard.eks_cluster_detail?input.eks_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "view-in-ar"
}

category "eks_fargate_profile" {
  title = "EKS Fargate Profile"
  color = local.containers_color
  icon  = "select-all"
}

category "eks_identity_provider_config" {
  title = "EKS Identity Provider Config"
  color = local.containers_color
  icon  = "groups-3"
}

category "eks_node_group" {
  title = "EKS Node Group"
  color = local.containers_color
  icon  = "device-hub"
}
