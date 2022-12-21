dashboard "elasticache_cluster_detail" {

  title         = "AWS ElastiCache Cluster Node Detail"
  documentation = file("./dashboards/elasticache/docs/elasticache_cluster_detail.md")

  tags = merge(local.elasticache_common_tags, {
    type = "Detail"
  })

  input "elasticache_cluster_arn" {
    title = "Select a Node:"
    query = query.elasticache_cluster_input
    width = 4
  }

  container {

    card {
      query = query.elasticache_cluster_status
      width = 2
      args  = [self.input.elasticache_cluster_arn.value]
    }

    card {
      query = query.elasticache_cluster_cache_node_count
      width = 2
      args  = [self.input.elasticache_cluster_arn.value]
    }

    card {
      query = query.elasticache_cluster_automatic_backup
      width = 2
      args  = [self.input.elasticache_cluster_arn.value]
    }

    card {
      query = query.elasticache_cluster_encryption_transit
      width = 2
      args  = [self.input.elasticache_cluster_arn.value]
    }

    card {
      query = query.elasticache_cluster_encryption_rest
      width = 2
      args  = [self.input.elasticache_cluster_arn.value]
    }

    card {
      query = query.elasticache_cluster_auth_token
      width = 2
      args  = [self.input.elasticache_cluster_arn.value]
    }
  }

  with "elasticache_cluster_nodes" {
    query = query.elasticache_cluster_elasticache_cluster_nodes
    args  = [self.input.elasticache_cluster_arn.value]
  }

  with "elasticache_node_groups" {
    query = query.elasticache_cluster_elasticache_node_groups
    args  = [self.input.elasticache_cluster_arn.value]
  }

  container {

    graph {
      title = "Relationships"
      type  = "graph"

      node {
        base = node.elasticache_cluster_node
        args = {
          elasticache_cluster_node_arns = with.elasticache_cluster_nodes.rows[*].elasticache_cluster_node_arn
        }
      }

      node {
        base = node.elasticache_node_group
        args = {
          elasticache_node_group_ids = with.elasticache_node_groups.rows[*].elasticache_node_group_id
        }
      }

      node {
        base = node.elasticache_cluster
        args = {
          elasticache_cluster_arns = [self.input.elasticache_cluster_arn.value]
        }
      }

      edge {
        base = edge.elasticache_cluster_to_elasticache_node_group
        args = {
          elasticache_cluster_arns = [self.input.elasticache_cluster_arn.value]
        }
      }

      edge {
        base = edge.elasticache_node_group_to_elasticache_cluster_node
        args = {
          elasticache_cluster_arns = [self.input.elasticache_cluster_arn.value]
        }
      }
    }
  }


  container {
    width = 6

    table {
      title = "Overview"
      type  = "line"
      query = query.elasticache_cluster_overview
      args  = [self.input.elasticache_cluster_arn.value]

    }
  }

  container {
    width = 6

    table {
      title = "Shard Details"
      query = query.elasticache_shard_details
      args  = [self.input.elasticache_cluster_arn.value]
    }
  }
}

# Input queries

query "elasticache_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_elasticache_replication_group
    order by
      title;
  EOQ
}

# Card queries

query "elasticache_cluster_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      case when cluster_enabled then 'Enabled' else 'Disabled' end as value
    from
      aws_elasticache_replication_group
    where
      arn = $1;
  EOQ
}

query "elasticache_cluster_cache_node_count" {
  sql = <<-EOQ
    select
      'Cache Nodes' as label,
      jsonb_array_length(member_clusters) as value
    from
      aws_elasticache_replication_group
    where
      arn = $1;
  EOQ
}

query "elasticache_cluster_automatic_backup" {
  sql = <<-EOQ
    select
      'Automatic Backup' as label,
      case when snapshot_retention_limit is null then 'Disabled' else 'Enabled' end as value,
      case when snapshot_retention_limit is null then 'alert' else 'ok' end as type
    from
      aws_elasticache_replication_group
    where
      arn = $1;
  EOQ
}

query "elasticache_cluster_encryption_transit" {
  sql = <<-EOQ
    select
      'Encryption in Transit' as label,
      case when transit_encryption_enabled then 'Enabled' else 'Disabled' end as value,
      case when transit_encryption_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_replication_group
    where
      arn = $1;
  EOQ
}

query "elasticache_cluster_encryption_rest" {
  sql = <<-EOQ
    select
      'Encryption at Rest' as label,
      case when at_rest_encryption_enabled then 'Enabled' else 'Disabled' end as value,
      case when at_rest_encryption_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_replication_group
    where
      arn = $1;
  EOQ
}

query "elasticache_cluster_auth_token" {
  sql = <<-EOQ
    select
      'Auth Token' as label,
      case when auth_token_enabled then 'Enabled' else 'Disabled' end as value,
      case when auth_token_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_replication_group
    where
      arn = $1;
  EOQ
}

# With queries

query "elasticache_cluster_elasticache_cluster_nodes" {
  sql = <<-EOQ
    select
      c.arn as elasticache_cluster_node_arn
    from
      aws_elasticache_cluster as c,
      aws_elasticache_replication_group as g
    where
      c.replication_group_id = g.replication_group_id
      and g.arn = $1;
  EOQ
}

query "elasticache_cluster_elasticache_node_groups" {
  sql = <<-EOQ
    select
      (rg.title || '-' || (ng ->> 'NodeGroupId')) as elasticache_node_group_id
    from
      aws_elasticache_replication_group rg,
      jsonb_array_elements(node_groups) ng
    where
      rg.arn = $1;
  EOQ
}

# Other detail page queries

query "elasticache_cluster_overview" {
  sql = <<-EOQ
    select
      description as "Description",
      cluster_enabled as "Enabled",
      cache_node_type as "Node Type",
      multi_az as "Multi AZ",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_elasticache_replication_group
    where
      arn = $1;
  EOQ
}

query "elasticache_shard_details" {
  sql = <<-EOQ
    select
      rg.title || '-' || (ng ->> 'NodeGroupId') as "ID",
      jsonb_array_length(ng -> 'NodeGroupMembers') as "Members",
      (ng -> 'PrimaryEndpoint' ->> 'Address') || ':' || (ng -> 'PrimaryEndpoint' ->> 'Port') as "Primary Endpoint",
      (ng -> 'ReaderEndpoint' ->> 'Address') || ':' || (ng -> 'ReaderEndpoint' ->> 'Port') as "Reader Endpoint",
      ng ->> 'Slots' as "Slots",
      ng ->> 'Status' as "Status"
    from
      aws_elasticache_replication_group rg,
      jsonb_array_elements(node_groups) ng
    where
      arn = $1;
  EOQ
}