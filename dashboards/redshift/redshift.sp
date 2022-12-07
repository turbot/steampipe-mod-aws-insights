locals {
  redshift_common_tags = {
    service = "AWS/Redshift"
  }
}

category "redshift_cluster" {
  title = "Redshift Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.redshift_cluster_detail?input.cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "heroicons-outline:circle-stack"
}

category "redshift_parameter_group" {
  title = "Redshift Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}

category "redshift_snapshot" {
  title = "Redshift Snapshot"
  color = local.database_color
  href  = "/aws_insights.dashboard.redshift_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
  icon  = "heroicons-outline:viewfinder-circle"
}

category "redshift_subnet_group" {
  title = "Redshift Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}
