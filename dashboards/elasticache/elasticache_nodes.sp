node "elasticache_cluster" {
  category = category.elasticache_cluster

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Status', cache_cluster_status,
        'Encryption Enabled', at_rest_encryption_enabled::text,
        'Create Time', cache_cluster_create_time,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_elasticache_cluster
    where
      arn = any($1);
  EOQ

  param "elasticache_cluster_arns" {}
}

node "elasticache_node_group" {
  category = category.elasticache_node_group

  sql = <<-EOQ
    select
      rg.title || '-' || (ng ->> 'NodeGroupId') as id,
      rg.title || '-' || (ng ->> 'NodeGroupId') as title,
      jsonb_build_object(
        'Members', jsonb_array_length(ng -> 'NodeGroupMembers'),
        'Primary Endpoint', (ng -> 'PrimaryEndpoint' ->> 'Address') || ':' || (ng -> 'PrimaryEndpoint' ->> 'Port'),
        'Reader Endpoint', (ng -> 'ReaderEndpoint' ->> 'Address') || ':' || (ng -> 'ReaderEndpoint' ->> 'Port'),
        'Slots', ng ->> 'Slots',
        'Status', ng ->> 'Status' ) as properties
    from
      aws_elasticache_replication_group rg,
      jsonb_array_elements(node_groups) ng
    where
      (rg.title || '-' || (ng ->> 'NodeGroupId')) = any($1);
  EOQ

  param "elasticache_node_group_ids" {}
}

node "elasticache_parameter_group" {
  category = category.elasticache_parameter_group

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Is Global', is_global,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_elasticache_parameter_group
    where
      arn = any($1);
  EOQ

  param "elsticache_parameter_group_arns" {}
}

node "elasticache_replication_group" {
  category = category.elasticache_replication_group

  sql = <<-EOQ
    select
      arn as id,
      title,
      jsonb_build_object(
        'ARN', arn,
        'Description', description,
        'Enabled', cluster_enabled,
        'Node Type', cache_node_type,
        'Multi AZ', multi_az,
        'Region', region ) as properties
    from
      aws_elasticache_replication_group
    where
      arn = any($1);
  EOQ

  param "elasticache_replication_group_arns" {}
}

node "elasticache_subnet_group" {
  category = category.elasticache_subnet_group

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'VPC ID', vpc_id,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_elasticache_subnet_group
    where
      arn = any($1);
  EOQ

  param "elasticache_subnet_group_arns" {}
}