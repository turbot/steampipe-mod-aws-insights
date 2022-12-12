locals {
  dax_common_tags = {
    service = "AWS/DAX"
  }
}

category "dax_cluster" {
  title = "DAX Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.dax_cluster_detail?input.dax_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "database"
}

category "dax_cluster_node" {
  title = "DAX Cluster Node"
  color = local.database_color
  icon  = "database"
}

category "dax_parameter_group" {
  title = "DAX Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}

category "dax_subnet_group" {
  title = "DAX Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}
