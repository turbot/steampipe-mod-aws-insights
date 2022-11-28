locals {
  rds_common_tags = {
    service = "AWS/RDS"
  }
}

category "aws_rds_db_cluster" {
  title = "RDS DB Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_rds_db_cluster_detail.url_path?input.db_cluster_arn={{.properties.ARN | @uri}}"
  icon  = "circle-stack"
}

category "aws_rds_db_cluster_parameter_group" {
  title = "RDS DB Cluster Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}

category "aws_rds_db_cluster_snapshot" {
  title = "RDS DB Cluster Snapshot"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_rds_db_cluster_snapshot_detail.url_path?input.snapshot_arn={{.properties.ARN | @uri}}"
  icon  = "viewfinder-circle"
}

category "aws_rds_db_instance" {
  title = "RDS DB Instance"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_rds_db_instance_detail.url_path?input.db_instance_arn={{.properties.ARN | @uri}}"
  icon  = "circle-stack"
}

category "aws_rds_db_parameter_group" {
  title = "RDS DB Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}

category "aws_rds_db_snapshot" {
  title = "RDS DB Snapshot"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_rds_db_snapshot_detail.url_path?input.db_snapshot_arn={{.properties.ARN | @uri}}"
  icon  = "viewfinder-circle"
}

category "aws_rds_db_subnet_group" {
  title = "RDS DB Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}