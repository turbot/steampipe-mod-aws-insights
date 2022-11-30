dashboard "aws_elasticache_cluster_detail" {

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

  container {

    card {
      query = query.aws_elasticache_cluster_status
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

    card {
      query = query.aws_elasticache_cluster_node_type
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

    card {
      query = query.aws_elasticache_cluster_automatic_backup
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

    card {
      query = query.aws_elasticache_cluster_encryption_transit
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

    card {
      query = query.aws_elasticache_cluster_encryption_rest
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

    card {
      query = query.aws_elasticache_cluster_auth_token
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_elasticache_cluster_node,
        node.aws_elasticache_cluster_to_elasticache_parameter_group_node,
        node.aws_elasticache_cluster_to_sns_topic_node,
        node.aws_elasticache_cluster_to_kms_key_node,
        node.aws_elasticache_cluster_to_vpc_security_group_node,
        node.aws_elasticache_cluster_to_vpc_node,
        node.aws_elasticache_cluster_to_subnet_group_node,
        node.aws_elasticache_cluster_to_vpc_subnet_node,
        node.aws_elasticache_cluster_subnet_to_vpc_node
      ]

      edges = [
        edge.aws_elasticache_cluster_to_sns_topic_edge,
        edge.aws_elasticache_cluster_to_elasticache_parameter_group_edge,
        edge.aws_elasticache_cluster_to_kms_key_edge,
        edge.aws_elasticache_cluster_to_vpc_security_group_edge,
        edge.aws_elasticache_cluster_to_subnet_group_edge,
        edge.aws_elasticache_cluster_to_vpc_subnet_edge,
        edge.aws_elasticache_cluster_subnet_to_vpc_edge
      ]

      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_elasticache_cluster_overview
        args = {
          arn = self.input.elasticache_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_elasticache_cluster_tags
        args = {
          arn = self.input.elasticache_cluster_arn.value
        }

      }
    }
    container {
      width = 6

      table {
        title = "Notification Configuration"
        query = query.aws_elasticache_cluster_notification_configuration
        args = {
          arn = self.input.elasticache_cluster_arn.value
        }
      }
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

query "aws_elasticache_cluster_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(cache_cluster_status) as value
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_elasticache_cluster_node_type" {
  sql = <<-EOQ
    select
      'Node Type' as label,
      cache_node_type as value
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_elasticache_cluster_automatic_backup" {
  sql = <<-EOQ
    select
      'Automatic Backup' as label,
      case when snapshot_retention_limit is null then 'Disabled' else 'Enabled' end as value,
      case when snapshot_retention_limit is null then 'alert' else 'ok' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_elasticache_cluster_encryption_transit" {
  sql = <<-EOQ
    select
      'Encryption in Transit' as label,
      case when transit_encryption_enabled then 'Enabled' else 'Disabled' end as value,
      case when transit_encryption_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_elasticache_cluster_encryption_rest" {
  sql = <<-EOQ
    select
      'Encryption at Rest' as label,
      case when at_rest_encryption_enabled then 'Enabled' else 'Disabled' end as value,
      case when at_rest_encryption_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}

}

query "aws_elasticache_cluster_auth_token" {
  sql = <<-EOQ
    select
      'Auth Token' as label,
      case when auth_token_enabled then 'Enabled' else 'Disabled' end as value,
      case when auth_token_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}

}

node "aws_elasticache_cluster_node" {
  category = category.elasticache_cluster

  sql = <<-EOQ
    select
      cache_cluster_id as id,
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
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_elasticache_cluster_to_sns_topic_node" {
  category = category.sns_topic

  sql = <<-EOQ
    select
      topic_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', topic_arn,
        'Account ID', account_id,
        'Region', region ) as properties
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
      );
  EOQ

  param "arn" {}
}

edge "aws_elasticache_cluster_to_sns_topic_edge" {
  title = "notifies"

  sql = <<-EOQ
    select
      cache_cluster_id as from_id,
      topic_arn as to_id
    from
      aws_elasticache_cluster as c
      left join
        aws_sns_topic as t
        on notification_configuration ->> 'TopicArn' = topic_arn
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_elasticache_cluster_to_kms_key_node" {
  category = category.kms_key

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Key Manager', key_manager,
        'Creation Date', creation_date,
        'Enabled', enabled::text,
        'Account ID', account_id,
        'Region', region ) as properties
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
          c.arn = $1
          and c.replication_group_id = g.replication_group_id
      );
  EOQ

  param "arn" {}
}

edge "aws_elasticache_cluster_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      cache_cluster_id as from_id,
      k.id as to_id
    from
      aws_elasticache_cluster as c
      left join
        aws_elasticache_replication_group as g
        on c.replication_group_id = g.replication_group_id
      left join
        aws_kms_key as k
        on g.kms_key_id = k.arn
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_elasticache_cluster_to_vpc_security_group_node" {
  category = category.vpc_security_group

  sql = <<-EOQ
    select
      group_id as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'VPC ID', vpc_id,
        'Group ID', group_id,
        'Account ID', account_id,
        'Region', region ) as properties
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
      );
  EOQ

  param "arn" {}
}

edge "aws_elasticache_cluster_to_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      c.cache_cluster_id as from_id,
      g.group_id as to_id
    from
      aws_vpc_security_group as g,
      aws_elasticache_cluster as c,
      jsonb_array_elements(security_groups) as sg
    where
      sg ->> 'SecurityGroupId' = g.group_id
      and c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_elasticache_cluster_to_vpc_node" {
  category = category.vpc_vpc

  sql = <<-EOQ
    select
      vpc_id as id,
      title as title,
      jsonb_build_object(
        'VPC ID', vpc_id,
        'ARN', arn,
        'State', state,
        'CIDR Block', cidr_block,
        'Account ID', account_id,
        'Region', region ) as properties
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
      );
  EOQ

  param "arn" {}
}

node "aws_elasticache_cluster_to_subnet_group_node" {
  category = category.elasticache_subnet_group

  sql = <<-EOQ
    select
      g.arn as id,
      g.title as title,
      jsonb_build_object(
        'ARN', g.arn,
        'VPC ID', g.vpc_id,
        'Account ID', g.account_id,
        'Region', g.region ) as properties
    from
      aws_elasticache_cluster as c
      cross join jsonb_array_elements(security_groups) as sg
      join aws_elasticache_subnet_group as g
      on g.cache_subnet_group_name = c.cache_subnet_group_name
      and g.region = c.region
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_elasticache_cluster_to_subnet_group_edge" {
  title = "subnet group"

  sql = <<-EOQ
    select
       coalesce(
        sg ->> 'SecurityGroupId',
        c.cache_cluster_id
      ) as from_id,
      g.arn as to_id
    from
      aws_elasticache_cluster as c
      cross join jsonb_array_elements(security_groups) as sg
      join aws_elasticache_subnet_group as g
      on g.cache_subnet_group_name = c.cache_subnet_group_name
      and g.region = c.region
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_elasticache_cluster_to_elasticache_parameter_group_node" {
  category = category.elasticache_parameter_group

  sql = <<-EOQ
    select
      g.arn as id,
      g.title as title,
      jsonb_build_object(
        'ARN', g.arn,
        'Is Global', g.is_global,
        'Account ID', g.account_id,
        'Region', g.region ) as properties
    from
      aws_elasticache_cluster as c,
      aws_elasticache_parameter_group as g
    where
      c.cache_parameter_group ->> 'CacheParameterGroupName' = g.cache_parameter_group_name
      and c.region = g.region
      and c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_elasticache_cluster_to_elasticache_parameter_group_edge" {
  title = "parameter group"

  sql = <<-EOQ
    select
      c.cache_cluster_id as from_id,
      g.arn as to_id
    from
      aws_elasticache_cluster as c,
      aws_elasticache_parameter_group as g
    where
      c.cache_parameter_group ->> 'CacheParameterGroupName' = g.cache_parameter_group_name
      and c.region = g.region
      and c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_elasticache_cluster_to_vpc_subnet_node" {
  category = category.vpc_subnet

  sql = <<-EOQ
    select
      subnet_id as id,
      title as title,
      jsonb_build_object(
        'Subnet ID', subnet_id,
        'ARN', subnet_arn,
        'CIDR Block', cidr_block,
        'Account ID', account_id,
        'Region', region ) as properties
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
          g.cache_subnet_group_name = c.cache_subnet_group_name
          and g.region = c.region
          and c.arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_elasticache_cluster_to_vpc_subnet_edge" {
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
      and c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_elasticache_cluster_subnet_to_vpc_node" {
  category = category.vpc_vpc

  sql = <<-EOQ
    select
      vpc_id as id,
      title as title,
      jsonb_build_object(
        'VPC ID', vpc_id,
        'ARN', arn,
        'State', state,
        'CIDR Block', cidr_block,
        'Account ID', account_id,
        'Region', region ) as properties
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
          g.cache_subnet_group_name = c.cache_subnet_group_name
          and g.region = c.region
          and c.arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_elasticache_cluster_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet ->> 'SubnetIdentifier' as from_id,
      g.vpc_id as to_id
    from
      aws_elasticache_cluster as c,
      aws_elasticache_subnet_group as g,
      jsonb_array_elements(subnets) as subnet
    where
      g.cache_subnet_group_name = c.cache_subnet_group_name
      and c.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_elasticache_cluster_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      auth_token_enabled as "Auth Token Enabled",
      auto_minor_version_upgrade as "Auto Minor Version Upgrade",
      cache_cluster_create_time as "Create Time",
      cache_subnet_group_name as "Subnet Group Name",
      engine as "Engine",
      engine_version as "Engine Version",
      preferred_availability_zone as "Preferred Availability Zone",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_elasticache_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_elasticache_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_elasticache_cluster_notification_configuration" {
  sql = <<-EOQ
    select
      t.title as "Topic Title",
      notification_configuration ->> 'TopicStatus' as "Topic Status"
    from
      aws_elasticache_cluster as c
      left join
        aws_sns_topic as t
        on notification_configuration ->> 'TopicArn' = topic_arn
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_elasticache_cluster_nodes" {
  category = category.elasticache_cluster

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Cache Cluster ID', cache_cluster_id,
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
