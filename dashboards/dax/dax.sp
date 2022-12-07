locals {
  dax_common_tags = {
    service = "AWS/DAX"
  }
}

category "dax_cluster" {
  title = "DAX Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.dax_cluster_detail?input.dax_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "clipboard-document-check"
}

category "dax_cluster_node" {
  title = "DAX Cluster Node"
  color = local.database_color
  icon  = "text:Node"
}

category "dax_subnet_group" {
  title = "DAX Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}

category "dax_parameter_group" {
  title = "DAX Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}
