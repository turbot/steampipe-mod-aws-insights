locals {
  elasticache_common_tags = {
    service = "AWS/ElastiCache"
  }
}

category "elasticache_cluster" {
  title = "ElastiCache Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.elasticache_cluster_detail.url_path?input.elasticache_cluster_arn={{.properties.ARN | @uri}}"
  icon  = "database"
}

category "elasticache_node_group" {
  # Following the AWS console terminology(Shard) over AWS CLI/API terminology(Node Group)
  # https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/WhatIs.Terms.html
  title = "ElastiCache Shard"
  color = local.database_color
  icon  = "device-hub"
}

category "elasticache_parameter_group" {
  title = "ElastiCache Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}

category "elasticache_replication_group" {
  title = "ElastiCache Replication Group"
  color = local.database_color
  icon  = "hub"
}

category "elasticache_subnet_group" {
  title = "ElastiCache Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}
