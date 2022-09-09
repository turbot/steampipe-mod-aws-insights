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
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_dax_cluster_relationships_graph
      args = {
        arn = self.input.dax_cluster_arn.value
      }
      category "aws_dax_cluster" {}
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

query "aws_dax_cluster_relationships_graph" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_dax_cluster' as category,
      jsonb_build_object(
        'ARN', arn,
        'Name', cluster_name,
        'Status', status,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_dax_cluster
    where
      arn = $1

    -- From IAM roles (node)
    union all
     select
      null as from_id,
      null as to_id,
      role_id as id,
      name as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', arn,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id ) as properties
    from
      aws_iam_role
    where
      arn in
      (
        select
          iam_role_arn
        from
          aws_dax_cluster
        where
          arn = $1
      )

    -- From IAM roles (edge)
    union all
     select
      c.arn as from_id,
      r.role_id as to_id,
      null as id,
      'iam role' as title,
      'dax_cluster_to_iam_role' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_iam_role as r,
      aws_dax_cluster as c
    where
      r.arn = c.iam_role_arn
      and c.arn = $1

    -- From VPC security groups (node)
    union all
     select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'Group ID', group_id,
        'Description', description,
        'ARN', arn,
        'Account ID', account_id,
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
      )

    -- From VPC security groups (edge)
    union all
     select
      c.arn as from_id,
      sg.arn as to_id,
      null as id,
      'security group' as title,
      'dax_cluster_to_vpc_security_group' as category,
      jsonb_build_object(
        'Account ID', c.account_id) as properties
    from
      aws_dax_cluster as c,
      jsonb_array_elements(security_groups) as s
      join aws_vpc_security_group sg
        on sg.group_id = s ->> 'SecurityGroupIdentifier'
    where
      c.arn = $1

    -- From Subnet groups (node)
    union all
     select
      null as from_id,
      null as to_id,
      subnet_group_name as id,
      title as title,
      'aws_dax_subnet_group' as category,
      jsonb_build_object(
        'Name', subnet_group_name,
        'Account ID', account_id,
        'Region', region ) as properties
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
      )

    -- From Subnet groups (edge)
    union all
     select
      c.arn as from_id,
      g.title as to_id,
      null as id,
      'subnet group' as title,
      'dax_cluster_to_dax_subnet_group' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_dax_cluster as c
      left join
        aws_dax_subnet_group as g
        on g.subnet_group_name = c.subnet_group
    where
      c.arn = $1

    -- From VPC subnets (node)
    union all
     select
      null as from_id,
      null as to_id,
      subnet_arn as id,
      title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', subnet_arn,
        'Subnet ID', subnet_id,
        'Account ID', account_id,
        'Region', region) as properties
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
      )

     -- From VPC subnets (edge)
    union all
     select
      g.title as from_id,
      sub.subnet_arn as to_id,
      null as id,
      'subnet' as title,
      'dax_subnet_group_vpc_subnet' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_vpc_subnet as sub,
      aws_dax_cluster as c,
      aws_dax_subnet_group as g,
      jsonb_array_elements(subnets) as s
    where
      g.subnet_group_name = c.subnet_group
      and s ->> 'SubnetIdentifier' = sub.subnet_id
      and c.arn = $1

    -- From SNS topics (node)
    union all
     select
      null as from_id,
      null as to_id,
      topic_arn as id,
      title as title,
      'aws_sns_topic' as category,
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
          aws_dax_cluster
        where
          arn = $1
      )

     -- From SNS topics (edge)
    union all
     select
      c.arn as from_id,
      t.topic_arn as to_id,
      null as id,
      'publishes to' as title,
      'dax_cluster_to_sns_topic' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_dax_cluster as c
      left join
        aws_sns_topic as t
        on t.topic_arn = c.notification_configuration ->> 'TopicArn'
    where
      c.arn = $1

     -- From VPCs (node)
    union all
     select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', arn,
        'VPC ID', vpc_id,
        'Account ID', account_id,
        'Region', region ) as properties
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
      )

     -- From Security group - VPC (edge)
    union all
     select
      sg.arn as from_id,
      v.arn as to_id,
      null as id,
      'vpc' as title,
      'vpc_security_group_to_vpc' as category,
      jsonb_build_object(
        'Account ID', c.account_id) as properties
    from
      aws_dax_cluster as c,
      jsonb_array_elements(security_groups) as s
      join aws_vpc_security_group sg
        on sg.group_id = s ->> 'SecurityGroupIdentifier'
      join aws_vpc v
        on v.vpc_id = sg.vpc_id
    where
      c.arn = $1

    -- From Subnet - VPC (edge)
    union all
     select
      sub.subnet_arn as from_id,
      v.arn as to_id,
      null as id,
      'vpc' as title,
      'vpc_subnet_to_vpc' as category,
      jsonb_build_object(
        'Account ID', c.account_id) as properties
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
      and c.arn = $1

    order by
      category,
      from_id,
      to_id;
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
