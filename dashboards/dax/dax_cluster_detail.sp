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
      width = 2
      args = {
        arn = self.input.dax_cluster_arn.value
      }
    }

    card {
      query = query.dax_cluster_node_type
      width = 2
      args = {
        arn = self.input.dax_cluster_arn.value
      }
    }

    card {
      query = query.dax_cluster_encryption
      width = 2
      args = {
        arn = self.input.dax_cluster_arn.value
      }
    }

  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "iam_role_arns" {
        sql = <<-EOQ
          select
            iam_role_arn
          from
            aws_dax_cluster
          where
            arn = $1;
        EOQ

        args = [self.input.dax_cluster_arn.value]
      }

      with "vpc_security_groups" {
        sql = <<-EOQ
          select
          sg ->> 'SecurityGroupIdentifier' as security_group_id
        from
          aws_dax_cluster,
          jsonb_array_elements(security_groups) as sg
        where
          arn = $1
        EOQ

        args = [self.input.dax_cluster_arn.value]
      }

      with "vpc_subnets" {
        sql = <<-EOQ
          select
          s ->> 'SubnetIdentifier' as subnet_id
        from
          aws_dax_cluster as c,
          aws_dax_subnet_group as g,
          jsonb_array_elements(subnets) as s
        where
          g.subnet_group_name = c.subnet_group
          and c.arn = $1
        EOQ

        args = [self.input.dax_cluster_arn.value]
      }

      with "sns_topics" {
        sql = <<-EOQ
        select
          notification_configuration ->> 'TopicArn' as topic_arn
        from
          aws_dax_cluster
        where
          arn = $1
        EOQ

        args = [self.input.dax_cluster_arn.value]
      }

      with "dax_subnet_groups" {
        sql = <<-EOQ
        select
          subnet_group as subnet_group_name
        from
          aws_dax_cluster
        where
          arn = $1
        EOQ

        args = [self.input.dax_cluster_arn.value]
      }

      with "dax_parameter_groups" {
        sql = <<-EOQ
        select
          p.parameter_group_name as parameter_group_name
        from
          aws_dax_parameter_group as p,
          aws_dax_cluster as c
        where
          c.parameter_group ->> 'ParameterGroupName' = p.parameter_group_name
          and c.arn = $1
        EOQ

        args = [self.input.dax_cluster_arn.value]
      }

      with "vpc_vpcs" {
        sql = <<-EOQ
        select
          sg.vpc_id as vpc_id
        from
          aws_dax_cluster as c,
          jsonb_array_elements(security_groups) as s
          join aws_vpc_security_group sg
            on sg.group_id = s ->> 'SecurityGroupIdentifier'
        where
          c.arn = $1
        EOQ

        args = [self.input.dax_cluster_arn.value]
      }

      nodes = [
        node.dax_cluster,
        node.dax_parameter_group,
        node.dax_subnet_group,
        node.iam_role,
        node.sns_topic,
        node.vpc_security_group,
        node.vpc_subnet,
        node.vpc_vpc
      ]

      edges = [
        edge.dax_cluster_to_iam_role,
        edge.dax_cluster_to_dax_parameter_group,
        edge.dax_cluster_to_sns_topic,
        edge.dax_cluster_to_vpc_security_group,
        edge.dax_subnet_group_to_vpc_subnet,
        edge.vpc_security_group_to_dax_subnet_group,
        edge.vpc_subnet_to_vpc_vpc
      ]

      args = {
        dax_cluster_arns          = [self.input.dax_cluster_arn.value]
        iam_role_arns             = with.iam_role_arns.rows[*].iam_role_arn
        dax_parameter_group_names = with.dax_parameter_groups.rows[*].parameter_group_name
        vpc_security_group_ids    = with.vpc_security_groups.rows[*].security_group_id
        vpc_subnet_ids            = with.vpc_subnets.rows[*].subnet_id
        sns_topic_arns            = with.sns_topics.rows[*].topic_arn
        dax_subnet_group_names    = with.dax_subnet_groups.rows[*].subnet_group_name
        vpc_vpc_ids               = with.vpc_vpcs.rows[*].vpc_id
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
        args = {
          arn = self.input.dax_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.dax_cluster_tags
        args = {
          arn = self.input.dax_cluster_arn.value
        }

      }
    }
    container {
      width = 6

      table {
        title = "Cluster Discovery Endpoint"
        query = query.dax_cluster_discovery_endpoint
        args = {
          arn = self.input.dax_cluster_arn.value
        }
      }

      table {
        title = "Nodes"
        query = query.dax_cluster_node_details
        args = {
          arn = self.input.dax_cluster_arn.value
        }
      }
    }
  }

}

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

query "dax_cluster_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value
    from
      aws_dax_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "dax_cluster_node_type" {
  sql = <<-EOQ
    select
      'Node Type' as label,
      node_type as value
    from
      aws_dax_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
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
      arn = $1;
  EOQ

  param "arn" {}
}

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
      arn = $1;
  EOQ

  param "arn" {}
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
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
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
      arn = $1;
  EOQ

  param "arn" {}
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
      arn = $1;
  EOQ

  param "arn" {}
}
