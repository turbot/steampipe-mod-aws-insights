
edge "elasticache_cluster_to_elasticache_parameter_group" {
  title = "parameter group"

  sql = <<-EOQ
    select
      c.arn as from_id,
      g.arn as to_id
    from
      aws_elasticache_cluster as c,
      aws_elasticache_parameter_group as g
    where
      c.cache_parameter_group ->> 'CacheParameterGroupName' = g.cache_parameter_group_name
      and c.region = g.region
      and g.arn = any($1);
  EOQ

  param "elsticache_parameter_group_arns" {}
}

edge "elasticache_cluster_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      c.arn as from_id,
      kms_key_id as to_id
    from
      aws_elasticache_cluster as c,
      aws_elasticache_replication_group as g
    where
      c.replication_group_id = g.replication_group_id
      and kms_key_id = any($1);
  EOQ

  param "kms_key_arns" {}
}

edge "elasticache_cluster_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      arn as from_id,
      notification_configuration ->> 'TopicArn' as to_id
    from
      aws_elasticache_cluster as c
    where
      arn = any($1);
  EOQ

  param "elasticache_cluster_arns" {}
}

edge "elasticache_cluster_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      c.arn as from_id,
      g.group_id as to_id
    from
      aws_vpc_security_group as g,
      aws_elasticache_cluster as c,
      jsonb_array_elements(security_groups) as sg
    where
      sg ->> 'SecurityGroupId' = g.group_id
      and g.group_id = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "elasticache_subnet_group_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      g.arn as from_id,
      s.subnet_id as to_id
    from
      aws_elasticache_cluster as c,
      aws_vpc_subnet as s,
      aws_elasticache_subnet_group as g,
      jsonb_array_elements(subnets) as subnet
    where
      g.cache_subnet_group_name = c.cache_subnet_group_name
      and subnet ->> 'SubnetIdentifier' = s.subnet_id
      and subnet_id = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}
