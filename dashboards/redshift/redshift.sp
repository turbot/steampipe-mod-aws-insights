locals {
  redshift_common_tags = {
    service = "AWS/Redshift"
  }
}

category "aws_redshift_cluster" {
  title = "Redshift Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_redshift_cluster_detail?input.cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "circle-stack"
}

category "aws_redshift_parameter_group" {
  title = "Redshift Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}

category "aws_redshift_snapshot" {
  title = "Redshift Snapshot"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_redshift_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
  icon  = "viewfinder-circle"
}

category "aws_redshift_subnet_group" {
  title = "Redshift Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}
