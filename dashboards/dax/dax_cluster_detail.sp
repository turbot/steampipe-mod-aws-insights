dashboard "dax_cluster_detail" {

  title         = "AWS DAX Cluster Detail"
  documentation = file("./dashboards/dax/docs/dax_cluster_detail.md")

  tags = merge(local.dax_common_tags, {
    type = "Detail"
  })

  input "dax_cluster_arn" {
    title = "Select a cluster:"
    query = query.dax_cluster_input
    width = 4
  }

  container {

    card {
      query = query.dax_cluster_status
      width = 3
      args  = [self.input.dax_cluster_arn.value]
    }

    card {
      query = query.dax_cluster_node_type
      width = 3
      args  = [self.input.dax_cluster_arn.value]
    }

    card {
      query = query.dax_cluster_encryption
      width = 3
      args  = [self.input.dax_cluster_arn.value]
    }
  }

  with "iam_roles_for_dax_cluster" {
    query = query.iam_roles_for_dax_cluster
    args  = [self.input.dax_cluster_arn.value]
  }

  with "sns_topics_for_dax_cluster" {
    query = query.sns_topics_for_dax_cluster
    args  = [self.input.dax_cluster_arn.value]
  }

  with "vpc_security_groups_for_dax_cluster" {
    query = query.vpc_security_groups_for_dax_cluster
    args  = [self.input.dax_cluster_arn.value]
  }

  with "vpc_subnets_for_dax_cluster" {
    query = query.vpc_subnets_for_dax_cluster
    args  = [self.input.dax_cluster_arn.value]
  }

  with "vpc_vpcs_for_dax_cluster" {
    query = query.vpc_vpcs_for_dax_cluster
    args  = [self.input.dax_cluster_arn.value]
  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.dax_cluster
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      node {
        base = node.dax_cluster_node
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      node {
        base = node.dax_parameter_group
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      node {
        base = node.dax_subnet_group
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      node {
        base = node.iam_role
        args = {
          iam_role_arns = with.iam_roles_for_dax_cluster.rows[*].iam_role_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics_for_dax_cluster.rows[*].topic_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_dax_cluster.rows[*].security_group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_dax_cluster.rows[*].subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_dax_cluster.rows[*].vpc_id
        }
      }

      edge {
        base = edge.dax_cluster_to_dax_cluster_node
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      edge {
        base = edge.dax_cluster_to_dax_parameter_group
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      edge {
        base = edge.dax_cluster_to_iam_role
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      edge {
        base = edge.dax_cluster_to_sns_topic
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      edge {
        base = edge.dax_cluster_to_vpc_security_group
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      edge {
        base = edge.dax_subnet_group_to_vpc_subnet
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_dax_subnet_group
        args = {
          dax_cluster_arns = [self.input.dax_cluster_arn.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_dax_cluster.rows[*].subnet_id
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
        query = query.dax_cluster_overview
        args  = [self.input.dax_cluster_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.dax_cluster_tags
        args  = [self.input.dax_cluster_arn.value]

      }
    }
    container {
      width = 6

      table {
        title = "Cluster Discovery Endpoint"
        query = query.dax_cluster_discovery_endpoint
        args  = [self.input.dax_cluster_arn.value]
      }

      table {
        title = "Nodes"
        query = query.dax_cluster_node_details
        args  = [self.input.dax_cluster_arn.value]
      }
    }
  }

}

# Input queries

query "dax_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_dax_cluster
    order by
      arn;
  EOQ
}

# With queries

query "iam_roles_for_dax_cluster" {
  sql = <<-EOQ
    select
      iam_role_arn
    from
      aws_dax_cluster
    where
      arn = $1
      and iam_role_arn is not null
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "sns_topics_for_dax_cluster" {
  sql = <<-EOQ
    select
      notification_configuration ->> 'TopicArn' as topic_arn
    from
      aws_dax_cluster
    where
      notification_configuration ->> 'TopicArn' is not null
      and arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_security_groups_for_dax_cluster" {
  sql = <<-EOQ
    select
      sg ->> 'SecurityGroupIdentifier' as security_group_id
    from
      aws_dax_cluster,
      jsonb_array_elements(security_groups) as sg
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_subnets_for_dax_cluster" {
  sql = <<-EOQ
    with cluster_details as (
      select
        subnet_group
      from
        aws_dax_cluster
      where
        arn = $1
        and account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    ),
    subnet_group_details as (
      select
        jsonb_array_elements(g.subnets) ->> 'SubnetIdentifier' as subnet_id
      from
        aws_dax_subnet_group g
      join
        cluster_details c on g.subnet_group_name = c.subnet_group
      where
        g.account_id = split_part($1, ':', 5)
        and g.region = split_part($1, ':', 4)
    )
    select
      subnet_id
    from
      subnet_group_details;
  EOQ
}

query "vpc_vpcs_for_dax_cluster" {
  sql = <<-EOQ
    with cluster_subnet_group as (
      select
        subnet_group
      from
        aws_dax_cluster
      where
        arn = $1
        and account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    )
    select
      g.vpc_id as vpc_id
    from
      aws_dax_subnet_group g
    join
      cluster_subnet_group csg on g.subnet_group_name = csg.subnet_group
    where
      g.account_id = split_part($1, ':', 5)
      and g.region = split_part($1, ':', 4);
  EOQ
}

# Card queries

query "dax_cluster_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value
    from
      aws_dax_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "dax_cluster_node_type" {
  sql = <<-EOQ
    select
      'Node Type' as label,
      node_type as value
    from
      aws_dax_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "dax_cluster_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when sse_description ->> 'Status' = 'ENABLED' then 'Enabled' else 'Disabled' end as value,
      case when sse_description ->> 'Status' = 'ENABLED' then 'ok' else 'alert' end as type
    from
      aws_dax_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

# Other detail page queries

query "dax_cluster_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      active_nodes as "Active Nodes",
      preferred_maintenance_window as "Preferred Maintenance Window",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_dax_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "dax_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_dax_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
    order by
      tag ->> 'Key';
  EOQ
}

query "dax_cluster_discovery_endpoint" {
  sql = <<-EOQ
    select
      cluster_discovery_endpoint ->> 'Address' as "Address",
      cluster_discovery_endpoint ->> 'Port' as "Port",
      cluster_discovery_endpoint ->> 'URL' as "URL"
    from
      aws_dax_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "dax_cluster_node_details" {
  sql = <<-EOQ
    select
      n ->> 'NodeId' as "Node ID",
      n ->> 'NodeStatus' as "Node Status",
      n ->> 'NodeCreateTime' as "Node Create Time",
      n ->> 'AvailabilityZone' as "Availability Zone",
      n ->> 'ParameterGroupStatus' as "Parameter Group Status"
    from
      aws_dax_cluster,
      jsonb_array_elements(nodes) as n
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}