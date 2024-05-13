dashboard "elasticache_cluster_node_detail" {

  title         = "AWS ElastiCache Cluster Node Detail"
  documentation = file("./dashboards/elasticache/docs/elasticache_cluster_node_detail.md")

  tags = merge(local.elasticache_common_tags, {
    type = "Detail"
  })

  input "elasticache_cluster_node_arn" {
    title = "Select a Node:"
    query = query.elasticache_cluster_node_input
    width = 4
  }

  container {

    card {
      query = query.elasticache_cluster_node_status
      width = 2
      args  = [self.input.elasticache_cluster_node_arn.value]
    }

    card {
      query = query.elasticache_cluster_node_node_type
      width = 2
      args  = [self.input.elasticache_cluster_node_arn.value]
    }

    card {
      query = query.elasticache_cluster_node_automatic_backup
      width = 2
      args  = [self.input.elasticache_cluster_node_arn.value]
    }

    card {
      query = query.elasticache_cluster_node_encryption_transit
      width = 2
      args  = [self.input.elasticache_cluster_node_arn.value]
    }

    card {
      query = query.elasticache_cluster_node_encryption_rest
      width = 2
      args  = [self.input.elasticache_cluster_node_arn.value]
    }

    card {
      query = query.elasticache_cluster_node_auth_token
      width = 2
      args  = [self.input.elasticache_cluster_node_arn.value]
    }

  }

  with "elasticache_node_groups_for_elasticache_cluster_node" {
    query = query.elasticache_node_groups_for_elasticache_cluster_node
    args  = [self.input.elasticache_cluster_node_arn.value]
  }

  with "elasticache_parameter_groups_for_elasticache_cluster_node" {
    query = query.elasticache_parameter_groups_for_elasticache_cluster_node
    args  = [self.input.elasticache_cluster_node_arn.value]
  }

  with "elasticache_clusters_for_elasticache_cluster_node" {
    query = query.elasticache_clusters_for_elasticache_cluster_node
    args  = [self.input.elasticache_cluster_node_arn.value]
  }

  with "elasticache_subnet_groups_for_elasticache_cluster_node" {
    query = query.elasticache_subnet_groups_for_elasticache_cluster_node
    args  = [self.input.elasticache_cluster_node_arn.value]
  }

  with "kms_keys_for_elasticache_cluster_node" {
    query = query.kms_keys_for_elasticache_cluster_node
    args  = [self.input.elasticache_cluster_node_arn.value]
  }

  with "sns_topics_for_elasticache_cluster_node" {
    query = query.sns_topics_for_elasticache_cluster_node
    args  = [self.input.elasticache_cluster_node_arn.value]
  }

  with "vpc_security_groups_for_elasticache_cluster_node" {
    query = query.vpc_security_groups_for_elasticache_cluster_node
    args  = [self.input.elasticache_cluster_node_arn.value]
  }

  with "vpc_subnets_for_elasticache_cluster_node" {
    query = query.vpc_subnets_for_elasticache_cluster_node
    args  = [self.input.elasticache_cluster_node_arn.value]
  }

  with "vpc_vpcs_for_elasticache_cluster_node" {
    query = query.vpc_vpcs_for_elasticache_cluster_node
    args  = [self.input.elasticache_cluster_node_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.elasticache_cluster
        args = {
          elasticache_cluster_arns = with.elasticache_clusters_for_elasticache_cluster_node.rows[*].elasticache_cluster_arn
        }
      }

      node {
        base = node.elasticache_cluster_node
        args = {
          elasticache_cluster_node_arns = [self.input.elasticache_cluster_node_arn.value]
        }
      }

      node {
        base = node.elasticache_parameter_group
        args = {
          elsticache_parameter_group_arns = with.elasticache_parameter_groups_for_elasticache_cluster_node.rows[*].elasticache_parameter_group_arn
        }
      }

      node {
        base = node.elasticache_node_group
        args = {
          elasticache_node_group_ids = with.elasticache_node_groups_for_elasticache_cluster_node.rows[*].elasticache_node_group_id
        }
      }

      node {
        base = node.elasticache_subnet_group
        args = {
          elasticache_subnet_group_arns = with.elasticache_subnet_groups_for_elasticache_cluster_node.rows[*].elasticache_subnet_group_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_elasticache_cluster_node.rows[*].kms_key_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics_for_elasticache_cluster_node.rows[*].sns_topic_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_elasticache_cluster_node.rows[*].vpc_security_group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_elasticache_cluster_node.rows[*].vpc_subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_elasticache_cluster_node.rows[*].vpc_vpc_id
        }
      }

      edge {
        base = edge.elasticache_cluster_node_to_elasticache_parameter_group
        args = {
          elsticache_parameter_group_arns = with.elasticache_parameter_groups_for_elasticache_cluster_node.rows[*].elasticache_parameter_group_arn
        }
      }

      edge {
        base = edge.elasticache_cluster_node_to_kms_key
        args = {
          kms_key_arns = with.kms_keys_for_elasticache_cluster_node.rows[*].kms_key_arn
        }
      }

      edge {
        base = edge.elasticache_cluster_node_to_sns_topic
        args = {
          elasticache_cluster_node_arns = [self.input.elasticache_cluster_node_arn.value]
        }
      }

      edge {
        base = edge.elasticache_cluster_node_to_vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_elasticache_cluster_node.rows[*].vpc_security_group_id
        }
      }

      edge {
        base = edge.elasticache_cluster_to_elasticache_node_group
        args = {
          elasticache_cluster_arns = with.elasticache_clusters_for_elasticache_cluster_node.rows[*].elasticache_cluster_arn
        }
      }

      edge {
        base = edge.elasticache_node_group_to_elasticache_cluster_node
        args = {
          elasticache_cluster_arns = with.elasticache_clusters_for_elasticache_cluster_node.rows[*].elasticache_cluster_arn
        }
      }

      edge {
        base = edge.elasticache_subnet_group_to_vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_elasticache_cluster_node.rows[*].vpc_subnet_id
        }
      }

      edge {
        base = edge.vpc_security_group_to_elasticache_subnet_group
        args = {
          elasticache_cluster_node_arns = [self.input.elasticache_cluster_node_arn.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_elasticache_cluster_node.rows[*].vpc_subnet_id
        }
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
        query = query.elasticache_cluster_node_overview
        args  = [self.input.elasticache_cluster_node_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.elasticache_cluster_node_tags
        args  = [self.input.elasticache_cluster_node_arn.value]

      }
    }
    container {
      width = 6

      table {
        title = "Notification Configuration"
        query = query.elasticache_cluster_node_notification_configuration
        args  = [self.input.elasticache_cluster_node_arn.value]
      }
    }
  }
}

# Input queries

query "elasticache_cluster_node_input" {
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

# With queries

query "elasticache_parameter_groups_for_elasticache_cluster_node" {
  sql = <<-EOQ
    select
      g.arn as elasticache_parameter_group_arn
    from
      aws_elasticache_cluster as c,
      aws_elasticache_parameter_group as g
    where
      c.cache_parameter_group ->> 'CacheParameterGroupName' = g.cache_parameter_group_name
      and c.region = g.region
      and c.account_id = g.account_id
      and c.arn = $1;
  EOQ
}

query "elasticache_clusters_for_elasticache_cluster_node" {
  sql = <<-EOQ
    select
      g.arn as elasticache_cluster_arn
    from
      aws_elasticache_cluster as c,
      aws_elasticache_replication_group as g
    where
      c.replication_group_id = g.replication_group_id
      and c.arn = $1
      and c.account_id = split_part($1, ':', 5)
      and c.region = split_part($1, ':', 4);
  EOQ
}

query "elasticache_node_groups_for_elasticache_cluster_node" {
  sql = <<-EOQ
    select
      rg.title || '-' || (ng ->> 'NodeGroupId') as elasticache_node_group_id
    from
      aws_elasticache_cluster as c,
      aws_elasticache_replication_group rg,
      jsonb_array_elements(node_groups) ng,
      jsonb_array_elements(ng -> 'NodeGroupMembers') ngm
    where
      c.cache_cluster_id = ngm ->> 'CacheClusterId'
      and c.arn = $1
      and c.account_id = split_part($1, ':', 5)
      and c.region = split_part($1, ':', 4);
  EOQ
}

query "elasticache_subnet_groups_for_elasticache_cluster_node" {
  sql = <<-EOQ
    select
      g.arn as elasticache_subnet_group_arn
    from
      aws_elasticache_cluster as c,
      aws_elasticache_subnet_group as g
    where
      g.cache_subnet_group_name = c.cache_subnet_group_name
      and g.region = c.region
      and c.arn = $1
      and c.account_id = split_part($1, ':', 5);
  EOQ
}

query "kms_keys_for_elasticache_cluster_node" {
  sql = <<-EOQ
    select
      kms_key_id as kms_key_arn
    from
      aws_elasticache_cluster as c,
      aws_elasticache_replication_group as g
    where
      c.arn = $1
      and c.account_id = split_part($1, ':', 5)
      and c.region = split_part($1, ':', 4)
      and c.replication_group_id = g.replication_group_id
      and kms_key_id is not null;
  EOQ
}

query "sns_topics_for_elasticache_cluster_node" {
  sql = <<-EOQ
    select
      notification_configuration ->> 'TopicArn' as sns_topic_arn
    from
      aws_elasticache_cluster
    where
      arn = $1
      and notification_configuration ->> 'TopicArn' is not null
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_security_groups_for_elasticache_cluster_node" {
  sql = <<-EOQ
    select
      group_id as vpc_security_group_id
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
          and account_id = split_part($1, ':', 5)
          and region = split_part($1, ':', 4)
      );
  EOQ
}

query "vpc_subnets_for_elasticache_cluster_node" {
  sql = <<-EOQ
    select
      subnet ->> 'SubnetIdentifier' as vpc_subnet_id
    from
      aws_elasticache_cluster as c,
      aws_elasticache_subnet_group as g,
      jsonb_array_elements(subnets) as subnet
    where
      g.cache_subnet_group_name = c.cache_subnet_group_name
      and g.region = c.region
      and c.arn = $1
  EOQ
}

query "vpc_vpcs_for_elasticache_cluster_node" {
  sql = <<-EOQ
    select
      vpc_id as vpc_vpc_id
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
          and c.account_id = split_part($1, ':', 5)
      );
  EOQ
}

# Card queries

query "elasticache_cluster_node_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(cache_cluster_status) as value
    from
      aws_elasticache_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "elasticache_cluster_node_node_type" {
  sql = <<-EOQ
    select
      'Node Type' as label,
      cache_node_type as value
    from
      aws_elasticache_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "elasticache_cluster_node_automatic_backup" {
  sql = <<-EOQ
    select
      'Automatic Backup' as label,
      case when snapshot_retention_limit is null then 'Disabled' else 'Enabled' end as value,
      case when snapshot_retention_limit is null then 'alert' else 'ok' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "elasticache_cluster_node_encryption_transit" {
  sql = <<-EOQ
    select
      'Encryption in Transit' as label,
      case when transit_encryption_enabled then 'Enabled' else 'Disabled' end as value,
      case when transit_encryption_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "elasticache_cluster_node_encryption_rest" {
  sql = <<-EOQ
    select
      'Encryption at Rest' as label,
      case when at_rest_encryption_enabled then 'Enabled' else 'Disabled' end as value,
      case when at_rest_encryption_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "elasticache_cluster_node_auth_token" {
  sql = <<-EOQ
    select
      'Auth Token' as label,
      case when auth_token_enabled then 'Enabled' else 'Disabled' end as value,
      case when auth_token_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

# Other detail page queries

query "elasticache_cluster_node_overview" {
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
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "elasticache_cluster_node_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_elasticache_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
    order by
      tag ->> 'Key';
  EOQ
}

query "elasticache_cluster_node_notification_configuration" {
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
      c.arn = $1
      and c.account_id = split_part($1, ':', 5)
      and c.region = split_part($1, ':', 4);
  EOQ
}

