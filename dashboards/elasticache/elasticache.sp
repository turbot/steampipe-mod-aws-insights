locals {
  elasticache_common_tags = {
    service = "AWS/ElastiCache"
  }
}

category "elasticache_cluster_node" {
  title = "ElastiCache Cluster Node"
  color = local.database_color
  href  = "/aws_insights.dashboard.elasticache_cluster_node_detail?input.elasticache_cluster_node_arn={{.properties.ARN | @uri}}"
  icon  = "flash_on"
}

category "elasticache_node_group" {
  # Following the AWS console terminology(Shard) over AWS CLI/API terminology(Node Group)
  # https://docs.aws.amazon.com/AmazonElastiCache/latest/red_ug/WhatIs.Terms.html
  title = "ElastiCache Shard"
  color = local.database_color
  icon  = "device_hub"
}

category "elasticache_parameter_group" {
  title = "ElastiCache Parameter Group"
  color = local.database_color
  icon  = "tune"
}

category "elasticache_cluster" {
  title = "ElastiCache Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.elasticache_cluster_detail?input.elasticache_cluster_arn={{.properties.ARN | @uri}}"
  icon  = "hub"
}

category "elasticache_subnet_group" {
  title = "ElastiCache Subnet Group"
  color = local.database_color
  icon  = "account_tree"
}
