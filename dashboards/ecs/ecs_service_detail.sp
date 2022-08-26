dashboard "aws_ecs_service_detail" {

  title         = "AWS ECS Service Detail"
  documentation = file("./dashboards/ecs/docs/ecs_service_detail.md")

  tags = merge(local.ecs_common_tags, {
    type = "Detail"
  })

  input "service_arn" {
    title = "Select a service:"
    sql   = query.aws_ecs_service_input.sql
    width = 4
  }

  container {

    card {
      query = query.aws_ecs_service_status
      width = 2
      args = {
        arn = self.input.service_arn.value
      }
    }

    card {
      query = query.aws_ecs_service_launch_type
      width = 2
      args = {
        arn = self.input.service_arn.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      title = "Relationships"
      query = query.aws_ecs_service_relationships_graph
      args = {
        arn = self.input.service_arn.value
      }

      category "aws_ecs_service" {}

      category "aws_ecs_task" {
        icon = local.aws_ecs_task_icon
        fold {
          title     = "Tasks"
          threshold = 2
          icon      = "collections"
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
        query = query.aws_ecs_service_overview
        args = {
          arn = self.input.service_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_ecs_service_tags
        args = {
          arn = self.input.service_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Tasks"
        query = query.aws_ecs_service_tasks
        args = {
          arn = self.input.service_arn.value
        }
      }

    }

  }
}

query "aws_ecs_service_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'arn', arn
      ) as tags
    from
      aws_ecs_service
    order by
      title;
  EOQ
}

query "aws_ecs_service_status" {
  sql = <<-EOQ
    select
      initcap(status) as value,
      'Status' as label
    from
      aws_ecs_service
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_service_launch_type" {
  sql = <<-EOQ
    select
      launch_type as value,
      'Launch Type' as label
    from
      aws_ecs_service
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_service_overview" {
  sql = <<-EOQ
    select
      service_name as "Name",
      cluster_arn as "Cluster ARN",
      created_at as "Created At",
      created_by as "Created By",
      scheduling_strategy as "Scheduling Strategy",
      enable_ecs_managed_tags as "Enable ECS Managed Tags",
      enable_execute_command as "Enable Execute Command",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_ecs_service
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_service_tasks" {
  sql = <<-EOQ
    select
      desired_count as "Desired Count",
      pending_count as "Pending Count",
      running_count as "Running Count"
    from
      aws_ecs_service
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_service_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ecs_service,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_ecs_service_relationships_graph" {
  sql = <<-EOQ
    with ecs_service as (
      select
        *
      from
        aws_ecs_service
      where
        arn = $1
    )
    select
      null as from_id,
      null as to_id,
      arn as id,
      service_name as title,
      'aws_ecs_service' as category,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      ecs_service

    -- To ECS tasks (node)
    union all
    select
      null as from_id,
      null as to_id,
      t.task_arn as id,
      concat(split_part(t.task_arn, '/', 2),'/' ,split_part(t.task_arn, '/', 3)) as title,
      'aws_ecs_task' as category,
      jsonb_build_object(
        'ARN', t.task_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_ecs_task as t
    where
      t.service_name in (select service_name from ecs_service )
      and t.region in (select region from ecs_service )

    -- To ECS tasks (edge)
    union all
    select
      $1 as from_id,
      t.task_arn as to_id,
      null as id,
      'task' as title,
      'ecs_service_to_ecs_task' as category,
      jsonb_build_object(
        'ARN', t.task_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_ecs_task as t
    where
      t.service_name in (select service_name from ecs_service)
      and t.region in (select region from ecs_service)

     -- To ECS services role (node)
    union all
    select
      null as from_id,
      null as to_id,
      r.arn as id,
      r.name as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Create Date', r.create_date,
        'Account ID', r.account_id
      ) as properties
    from
      ecs_service as s
      left join aws_iam_role as r on r.arn = s.role_arn

    -- To ECS services role (edge)
    union all
    select
      s.arn as from_id,
      s.role_arn as to_id,
      null as id,
      'assumes' as title,
      'ecs_service_to_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Create Date', r.create_date,
        'Account ID', r.account_id
      ) as properties
    from
      ecs_service as s
      left join aws_iam_role as r on r.arn = s.role_arn

    -- To ECS services load balancing (node)
    union all
    select
      null as from_id,
      null as to_id,
      t.target_group_arn as id,
      t.target_group_name as title,
      'aws_ec2_target_group' as category,
      jsonb_build_object(
        'ARN', t.target_group_arn,
        'VPC ID', t.vpc_id,
        'Target Type', target_type,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      ecs_service as s,
      jsonb_array_elements(load_balancers) as l
      left join aws_ec2_target_group as t on t.target_group_arn = l ->> 'TargetGroupArn'

    -- To ECS services load balancing (edge)
    union all
    select
      s.arn as from_id,
      l ->> 'TargetGroupArn' as to_id,
      null as id,
      'load balancing' as title,
      'ecs_service_to_ec2_target_group' as category,
      jsonb_build_object(
        'ARN', t.target_group_arn,
        'VPC ID', t.vpc_id,
        'Target Type', target_type,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      ecs_service as s,
      jsonb_array_elements(load_balancers) as l
      left join aws_ec2_target_group as t on t.target_group_arn = l ->> 'TargetGroupArn'

    -- From ECS Cluster (node)
    union all
    select
      null as from_id,
      null as to_id,
      c.cluster_arn as id,
      c.cluster_name as title,
      'aws_ecs_cluster' as category,
      jsonb_build_object(
        'ARN', c.cluster_arn,
        'Status', c.status,
        'Account ID', c.account_id,
        'Region', c.region ) as properties
    from
      ecs_service as s
      left join aws_ecs_cluster as c on s.cluster_arn = c.cluster_arn

    -- From ECS Cluster (edge)
    union all
    select
      c.cluster_arn as from_id,
      s.arn to_id,
      null as id,
      'ecs cluster' as title,
      'ecs_cluster_to_ecs_service' as category,
      jsonb_build_object(
        'ARN', c.cluster_arn,
        'Status', c.status,
        'Account ID', c.account_id,
        'Region', c.region ) as properties
    from
      ecs_service as s
      left join aws_ecs_cluster as c on s.cluster_arn = c.cluster_arn

    -- To ECS conatiner instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      i.arn as id,
      e.title as title,
      'aws_ecs_container_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Instance ID', i.ec2_instance_id,
        'Status', i.status,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      ecs_service as s
      left join aws_ecs_container_instance as i on s.cluster_arn = i.cluster_arn
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id

    -- To ECS conatiner instances (edge)
    union all
    select
      s.arn as from_id,
      i.arn as to_id,
      null as id,
      'container instance' as title,
      'ecs_service_to_ecs_container_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Instance ID', i.ec2_instance_id,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      ecs_service as s
      left join aws_ecs_container_instance as i on s.cluster_arn = i.cluster_arn
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id

    -- To ECS services subnet (node)
    union all
    select
      null as from_id,
      null as to_id,
      sb.subnet_arn as id,
      sb.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', sb.subnet_arn,
        'Subnet ID', sb.subnet_id,
        'Account ID', sb.account_id,
        'Region', sb.region
      ) as properties
    from
      ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
    where
      e.network_configuration is not null

    -- To ECS services subnet (edge)
    union all
    select
      e.arn as from_id,
      sb.subnet_arn as to_id,
      null as id,
      'subnet' as title,
      'ecs_service_to_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', sb.subnet_arn,
        'Subnet ID', sb.subnet_id,
        'Account ID', sb.account_id,
        'Region', sb.region
      ) as properties
    from
      ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
    where
      e.network_configuration is not null

    -- To ECS services VPC (node)
    union all
    select
      null as from_id,
      null as to_id,
      v.arn as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'VPC ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
      ,aws_vpc as v
    where
      e.network_configuration is not null
      and v.vpc_id = sb.vpc_id

    -- To ECS services VPC (edge)
    union all
    select
      sb.subnet_arn as from_id,
      v.arn as to_id,
      null as id,
      'vpc' as title,
      'vpc_subnet_to_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'VPC ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
      ,aws_vpc as v
    where
      e.network_configuration is not null
      and v.vpc_id = sb.vpc_id

    -- To ECS task definitions (node)
    union all
    select
      null as from_id,
      null as to_id,
      d.task_definition_arn as id,
      d.title as title,
      'aws_ecs_task_definition' as category,
      jsonb_build_object(
        'ARN', d.task_definition_arn,
        'Account ID', d.account_id,
        'Region', d.region
      ) as properties
    from
      aws_ecs_task_definition as d
    where
      d.task_definition_arn in (select task_definition from ecs_service )

    -- To ECS task definitions (edge)
    union all
    select
      $1 as from_id,
      d.task_definition_arn as to_id,
      null as id,
      'task defintion' as title,
      'ecs_service_to_ecs_task_definition' as category,
      jsonb_build_object(
        'ARN', d.task_definition_arn,
        'Account ID', d.account_id,
        'Region', d.region
      ) as properties
    from
      aws_ecs_task_definition as d
    where
      d.task_definition_arn in (select task_definition from ecs_service )
  EOQ

  param "arn" {}
}
