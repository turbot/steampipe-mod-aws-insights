locals {
  redshift_common_tags = {
    service = "AWS/Redshift"
  }
}

category "redshift_cluster" {
  title = "Redshift Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.redshift_cluster_detail?input.cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "storage"
}

category "redshift_parameter_group" {
  title = "Redshift Parameter Group"
  color = local.database_color
  icon  = "tune"
}

category "redshift_snapshot" {
  title = "Redshift Snapshot"
  color = local.database_color
  href  = "/aws_insights.dashboard.redshift_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
  icon  = "add-a-photo"
}

category "redshift_subnet_group" {
  title = "Redshift Subnet Group"
  color = local.database_color
  icon  = "account-tree"
}
