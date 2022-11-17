dashboard "dax_cluster_detail" {

  title         = "AWS DAX Cluster Detail"
  documentation = file("./dashboards/dax/docs/dax_cluster_detail.md")

  tags = merge(local.dax_common_tags, {
    type = "Detail"
  })

  input "dax_cluster_arn" {
    title = "Select a cluster:"
    query = query.aws_dax_cluster_input
    width = 4
  }

  container {

    card {
      query = query.aws_dax_cluster_status
      width = 2
      args = {
        arn = self.input.dax_cluster_arn.value
      }
    }

    card {
      query = query.aws_dax_cluster_node_type
      width = 2
      args = {
        arn = self.input.dax_cluster_arn.value
      }
    }

    card {
      query = query.aws_dax_cluster_encryption
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

      nodes = [
        node.aws_dax_cluster_node,
        node.aws_dax_cluster_to_iam_role_node,
        node.aws_dax_cluster_to_vpc_security_group_node,
        node.aws_dax_cluster_to_dax_subnet_group_node,
        node.aws_dax_subnet_group_to_vpc_subnet_node,
        node.aws_dax_cluster_to_sns_topic_node,
        node.aws_dax_cluster_vpc_security_group_to_vpc_node
      ]

      edges = [
        edge.aws_dax_cluster_to_iam_role_edge,
        edge.aws_dax_cluster_to_vpc_security_group_edge,
        edge.aws_dax_cluster_to_dax_subnet_group_edge,
        edge.aws_dax_subnet_group_to_vpc_subnet_edge,
        edge.aws_dax_cluster_to_sns_topic_edge,
        edge.aws_dax_cluster_vpc_security_group_to_vpc_edge,
        edge.aws_dax_cluster_vpc_subnet_to_vpc_edge
      ]

      args = {
        arn = self.input.dax_cluster_arn.value
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
        query = query.aws_dax_cluster_overview
        args = {
          arn = self.input.dax_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_dax_cluster_tags
        args = {
          arn = self.input.dax_cluster_arn.value
        }

      }
    }
    container {
      width = 6

      table {
        title = "Cluster Discovery Endpoint"
        query = query.aws_dax_cluster_discovery_endpoint
        args = {
          arn = self.input.dax_cluster_arn.value
        }
      }

      table {
        title = "Nodes"
        query = query.aws_dax_cluster_nodes
        args = {
          arn = self.input.dax_cluster_arn.value
        }
      }
    }
  }

}

query "aws_dax_cluster_input" {
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

query "aws_dax_cluster_status" {
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

query "aws_dax_cluster_node_type" {
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

query "aws_dax_cluster_encryption" {
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

node "aws_dax_cluster_node" {
  category = category.aws_dax_cluster

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Cluster Name', cluster_name,
        'ARN', arn,
        'Account ID', account_id,
        'Name', title,
        'Region', region,
        'Status', status
      ) as properties
    from
      aws_dax_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_dax_cluster_to_iam_role_node" {
  category = category.aws_iam_role
  sql      = <<-EOQ
    select
      r.arn as id,
      r.title as title,
      json_build_object(
        'Name', name,
        'ARN', r.arn,
        'Account ID', r.account_id,
        'Create Date', r.create_date,
        'Max Session Duration', r.max_session_duration
      ) as properties
    from
      aws_dax_cluster as c,
      aws_iam_role as r
    where
      c.arn = $1
      and c.iam_role_arn = r.arn;
  EOQ

  param "arn" {}
}

edge "aws_dax_cluster_to_iam_role_edge" {
  title = "iam role"
  sql   = <<-EOQ
    select
      arn as from_id,
      iam_role_arn as to_id
    from
      aws_dax_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_dax_cluster_to_vpc_security_group_node" {
  category = category.aws_vpc_security_group
  sql      = <<-EOQ
    select
      arn as id,
      title as title,
      json_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Description', description,
        'Group ID', group_id,
        'Region', region
      ) as properties
    from
      aws_vpc_security_group
    where
      group_id in
      (
        select
          sg ->> 'SecurityGroupIdentifier'
        from
          aws_dax_cluster,
          jsonb_array_elements(security_groups) as sg
        where
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_dax_cluster_to_vpc_security_group_edge" {
  title = "security group"
  sql   = <<-EOQ
    select
      c.arn as from_id,
      sg.arn as to_id
    from
      aws_dax_cluster as c,
      jsonb_array_elements(security_groups) as s
      join aws_vpc_security_group sg on sg.group_id = s ->> 'SecurityGroupIdentifier'
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_dax_cluster_to_dax_subnet_group_node" {
  category = category.aws_dax_subnet_group
  sql      = <<-EOQ
    select
      subnet_group_name as id,
      title as title,
      jsonb_build_object(
        'Name', subnet_group_name,
        'VPC ID', vpc_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_dax_subnet_group
    where
      subnet_group_name in
      (
        select
          subnet_group
        from
          aws_dax_cluster
        where
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_dax_cluster_to_dax_subnet_group_edge" {
  title = "subnet group"
  sql   = <<-EOQ
    select
      c.arn as from_id,
      g.subnet_group_name as to_id
    from
      aws_dax_cluster as c
      left join aws_dax_subnet_group as g on g.subnet_group_name = c.subnet_group
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_dax_subnet_group_to_vpc_subnet_node" {
  category = category.aws_vpc_subnet
  sql      = <<-EOQ
    select
      subnet_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', subnet_arn,
        'Subnet ID', subnet_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_subnet
    where
      subnet_id in
      (
        select
          s ->> 'SubnetIdentifier'
        from
          aws_dax_cluster as c,
          aws_dax_subnet_group as g,
          jsonb_array_elements(subnets) as s
        where
          g.subnet_group_name = c.subnet_group
          and c.arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_dax_subnet_group_to_vpc_subnet_edge" {
  title = "subnet"
  sql   = <<-EOQ
    select
      g.subnet_group_name as from_id,
      sub.subnet_arn as to_id
    from
      aws_vpc_subnet as sub,
      aws_dax_cluster as c,
      aws_dax_subnet_group as g,
      jsonb_array_elements(subnets) as s
    where
      g.subnet_group_name = c.subnet_group
      and s ->> 'SubnetIdentifier' = sub.subnet_id
      and c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_dax_cluster_to_sns_topic_node" {
  category = category.aws_sns_topic
  sql      = <<-EOQ
    select
      topic_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', topic_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sns_topic
    where
      topic_arn in
      (
        select
          notification_configuration ->> 'TopicArn'
        from
          aws_dax_cluster
        where
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_dax_cluster_to_sns_topic_edge" {
  title = "publishes to"
  sql   = <<-EOQ
    select
      c.arn as from_id,
      t.topic_arn as to_id
    from
      aws_dax_cluster as c
      left join aws_sns_topic as t on t.topic_arn = c.notification_configuration ->> 'TopicArn'
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_dax_cluster_vpc_security_group_to_vpc_node" {
  category = category.aws_vpc
  sql      = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'VPC ID', vpc_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc
    where
      vpc_id in
      (
        select
          sg.vpc_id
        from
          aws_dax_cluster as c,
          jsonb_array_elements(security_groups) as s
          join aws_vpc_security_group sg
            on sg.group_id = s ->> 'SecurityGroupIdentifier'
        where
          c.arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_dax_cluster_vpc_security_group_to_vpc_edge" {
  title = "vpc"
  sql   = <<-EOQ
    select
      sg.arn as from_id,
      v.arn as to_id
    from
      aws_dax_cluster as c,
      jsonb_array_elements(security_groups) as s
      join aws_vpc_security_group sg on sg.group_id = s ->> 'SecurityGroupIdentifier'
      join aws_vpc v on v.vpc_id = sg.vpc_id
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_dax_cluster_vpc_subnet_to_vpc_edge" {
  title = "vpc"
  sql   = <<-EOQ
    select
      sub.subnet_arn as from_id,
      v.arn as to_id
    from
      aws_vpc as v,
      aws_vpc_subnet as sub,
      aws_dax_cluster as c,
      aws_dax_subnet_group as g,
      jsonb_array_elements(subnets) as s
    where
      g.subnet_group_name = c.subnet_group
      and s ->> 'SubnetIdentifier' = sub.subnet_id
      and g.vpc_id = v.vpc_id
      and c.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_dax_cluster_overview" {
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

query "aws_dax_cluster_tags" {
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

query "aws_dax_cluster_discovery_endpoint" {
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

query "aws_dax_cluster_nodes" {
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
