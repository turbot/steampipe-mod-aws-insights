locals {
  dax_common_tags = {
    service = "AWS/DAX"
  }
}

category "aws_dax_cluster" {
  title = "DAX Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.dax_cluster_detail?input.dax_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "clipboard-document-check"
}

category "aws_dax_subnet_group" {
  title = "DAX Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}