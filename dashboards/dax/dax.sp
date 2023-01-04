locals {
  dax_common_tags = {
    service = "AWS/DAX"
  }
}

category "dax_cluster" {
  title = "DAX Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.dax_cluster_detail?input.dax_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "speed"
}

category "dax_cluster_node" {
  title = "DAX Cluster Node"
  color = local.database_color
  icon  = "sd_card"
}

category "dax_parameter_group" {
  title = "DAX Parameter Group"
  color = local.database_color
  icon  = "tune"
}

category "dax_subnet_group" {
  title = "DAX Subnet Group"
  color = local.database_color
  icon  = "account_tree"
}
