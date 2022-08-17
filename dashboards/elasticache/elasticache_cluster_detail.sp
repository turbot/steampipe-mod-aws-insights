dashboard "elasticache_cluster_detail" {

  title         = "AWS ElastiCache Cluster Detail"
  documentation = file("./dashboards/elasticache/docs/elasticache_cluster_detail.md")

  tags = merge(local.elasticache_common_tags, {
    type = "Detail"
  })

  input "elasticache_cluster_arn" {
    title = "Select a Cluster:"
    query = query.aws_elasticache_cluster_input
    width = 4
  }

  graph {
    type  = "graph"
    title = "Relationships"
    query = query.aws_elasticache_cluster_relationships_graph
    args = {
      arn = self.input.elasticache_cluster_arn.value
    }
    category "aws_elasticache_cluster" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/elasticache_cluster_light.svg"))
    }

    category "aws_sns_topic" {
      href = "${dashboard.aws_sns_topic_detail.url_path}?input.topic_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/sns_topic_light.svg"))
    }

    category "aws_kms_key" {
      href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kms_key_light.svg"))
    }

    category "aws_vpc" {
      href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.'id' | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
    }

    category "aws_vpc_security_group" {
      href = "${dashboard.aws_vpc_security_group_detail.url_path}?input.security_group_id={{.'id' | @uri}}"
    }

    category "uses" {
      color = "green"
    }
  }
}


query "aws_elasticache_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_elasticache_cluster
    order by
      title;
  EOQ
}

query "aws_elasticache_cluster_relationships_graph" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      cache_cluster_id as id,
      title as title,
      'aws_elasticache_cluster' as category,
      jsonb_build_object( 'ARN', arn, 'Status', cache_cluster_status, 'Encryption Enabled', at_rest_encryption_enabled::text, 'Create Time', cache_cluster_create_time, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_elasticache_cluster
    where
      arn = $1

    -- To SNS Topics (node)
    union all
    select
      null as from_id,
      null as to_id,
      topic_arn as id,
      title as title,
      'aws_sns_topic' as category,
      jsonb_build_object( 'ARN', topic_arn, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_sns_topic
    where
      topic_arn in
      (
        select
          notification_configuration ->> 'TopicArn'
        from
          aws_elasticache_cluster
        where
          arn = $1
      )

    -- To SNS Topics (edge)
    union all
    select
      cache_cluster_id as from_id,
      topic_arn as to_id,
      null as id,
      'publishes to' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_elasticache_cluster as c
      left join
        aws_sns_topic as t
        on notification_configuration ->> 'TopicArn' = topic_arn
    where
      c.arn = $1

    -- To KMS Keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      id as id,
      title as title,
      'aws_kms_key' as category,
      jsonb_build_object( 'ARN', arn, 'Key Manager', key_manager, 'Creation Date', creation_date, 'Enabled', enabled, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_kms_key
    where
      arn in
      (
        select
          kms_key_id
        from
          aws_elasticache_cluster as c,
          aws_elasticache_replication_group as g
        where
          c.arn = $1 and c.replication_group_id = g.replication_group_id
      )

    -- To KMS Keys (edge)
    union all
    select
      cache_cluster_id as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_elasticache_cluster as c
      left join
        aws_elasticache_replication_group as g
        on c.replication_group_id = g.replication_group_id
      left join
        aws_kms_key as k
        on g.kms_key_id = k.arn
    where
      c.arn = $1

    -- To VPC Security Groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      group_id as id,
      title as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object( 'ARN', arn, 'VPC ID', vpc_id, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_vpc_security_group
    where
      group_id in
      (
        select
          sg ->> 'SecurityGroupId'
        from
          aws_elasticache_cluster,
          jsonb_array_elements(security_groups) as sg
        where
          arn = $1
      )

    -- To VPC Security Groups (edge)
    union all
    select
      c.cache_cluster_id as from_id,
      g.group_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_vpc_security_group as g,
      aws_elasticache_cluster as c,
      jsonb_array_elements(security_groups) as sg
    where
      sg ->> 'SecurityGroupId' = g.group_id
      and c.arn = $1

    -- To Security Groups -> VPC (node)
    union all
    select
      null as from_id,
      null as to_id,
      vpc_id as id,
      title as title,
      'aws_vpc' as category,
      jsonb_build_object( 'ARN', arn, 'State', state, 'CIDR Block', cidr_block, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_vpc
    where
      vpc_id in
      (
        select
          vpc_id
        from
          aws_vpc_security_group as g,
          aws_elasticache_cluster as c,
          jsonb_array_elements(security_groups) as sg
        where
          sg ->> 'SecurityGroupId' = g.group_id
          and c.arn = $1
      )

    -- To Security Groups -> VPC (edge)
    union all
    select
      g.group_id as from_id,
      g.vpc_id as to_id,
      null as id,
      'resides under' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_vpc_security_group as g,
      aws_elasticache_cluster as c,
      jsonb_array_elements(security_groups) as sg
    where
      sg ->> 'SecurityGroupId' = g.group_id
      and c.arn = $1

    -- To VPC Subnet Groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      cache_subnet_group_name as id,
      title as title,
      'aws_elasticache_subnet_group' as category,
      jsonb_build_object( 'ARN', arn, 'VPC ID', vpc_id, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_elasticache_subnet_group
    where
      cache_subnet_group_name in
      (
        select
          cache_subnet_group_name
        from
          aws_elasticache_cluster
        where
          arn = $1
      )

    -- To VPC Subnet Groups (edge)
    union all
    select
      c.cache_cluster_id as from_id,
      g.cache_subnet_group_name as to_id,
      null as id,
      'launched into' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_elasticache_cluster as c,
      aws_elasticache_subnet_group as g
    where
      g.cache_subnet_group_name = c.cache_subnet_group_name
      and c.arn = $1

    -- To VPC Subnets (node)
    union all
    select
      null as from_id,
      null as to_id,
      subnet_id as id,
      title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object( 'ARN', subnet_arn, 'CIDR Block', cidr_block, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_vpc_subnet
    where
      subnet_id in
      (
        select
          subnet ->> 'SubnetIdentifier'
        from
          aws_elasticache_cluster as c,
          aws_elasticache_subnet_group as g,
          jsonb_array_elements(subnets) as subnet
        where
          g.cache_subnet_group_name = c.cache_subnet_group_name and c.arn = $1
      )

    -- To VPC Subnets (edge)
    union all
    select
      g.cache_subnet_group_name as from_id,
      s.subnet_id as to_id,
      null as id,
      'contains' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_elasticache_cluster as c,
      aws_vpc_subnet as s,
      aws_elasticache_subnet_group as g,
      jsonb_array_elements(subnets) as subnet
    where
      g.cache_subnet_group_name = c.cache_subnet_group_name
      and subnet ->> 'SubnetIdentifier' = s.subnet_id
      and c.arn = $1

    -- To Subnet -> VPC (node)
    union all
    select
      null as from_id,
      null as to_id,
      vpc_id as id,
      title as title,
      'aws_vpc' as category,
      jsonb_build_object( 'ARN', arn, 'State', state, 'CIDR Block', cidr_block, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_vpc
    where
      vpc_id in
      (
        select
          vpc_id
        from
          aws_elasticache_cluster as c,
          aws_elasticache_subnet_group as g
        where
          g.cache_subnet_group_name = c.cache_subnet_group_name and c.arn = $1
      )

    -- To Subnet -> VPC (edge)
    union all
    select
      subnet ->> 'SubnetIdentifier' as from_id,
      g.vpc_id as to_id,
      null as id,
      'resides under' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_elasticache_cluster as c,
      aws_elasticache_subnet_group as g,
      jsonb_array_elements(subnets) as subnet
    where
      g.cache_subnet_group_name = c.cache_subnet_group_name
      and c.arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}
