dashboard "aws_ecs_cluster_detail" {

  title         = "AWS ECS Cluster Detail"
  documentation = file("./dashboards/ecs/docs/ecs_cluster_detail.md")

  tags = merge(local.ecs_common_tags, {
    type = "Detail"
  })

  input "ecs_cluster_arn" {
    title = "Select a cluster:"
    sql   = query.aws_ecs_cluster_input.sql
    width = 4
  }

  container {

    card {
      query = query.aws_ecs_cluster_status
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.aws_ecs_cluster_registered_container_instances_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.aws_ecs_cluster_pending_tasks_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.aws_ecs_cluster_running_tasks_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.aws_ecs_cluster_active_services_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      title = "Relationships"
      query = query.aws_ecs_cluster_relationships_graph
      args = {
        arn = self.input.ecs_cluster_arn.value
      }

      category "aws_ecs_task" {
        icon       = local.aws_ecs_task_icon
        fold {
          threshold  = 2
          title      = "Tasks..."
          icon =   local.aws_ecs_task_icon
        }
      }

      category "aws_ecs_task_definition" {
        fold {
          threshold  = 2
          title      = "TasksDefinitions..."
          icon =   "collection"
        }
      }

      category "aws_ecs_service" {
        icon = local.aws_ecs_service_icon
        fold {
          threshold  = 2
          title      = "Service..."
          icon       = local.aws_ecs_service_icon
        }
      }

      category "aws_ecs_container_instance" {
        color = "green"
      }

      category "launch_type" {
        color = "red"
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
        query = query.aws_ecs_cluster_overview
        args = {
          arn = self.input.ecs_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_ecs_cluster_tags
        args = {
          arn = self.input.ecs_cluster_arn.value
        }

      }
    }

    container {
      width = 6

    }

  }
}

query "aws_ecs_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      cluster_arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'cluster_arn', cluster_arn
      ) as tags
    from
      aws_ecs_cluster
    order by
      title;
  EOQ
}

query "aws_ecs_cluster_status" {
  sql = <<-EOQ
    select
      initcap(status) as value,
      'Status' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_registered_container_instances_count" {
  sql = <<-EOQ
    select
      registered_container_instances_count as value,
      'Registered Container Instances' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_pending_tasks_count" {
  sql = <<-EOQ
    select
      pending_tasks_count as value,
      'Pending Tasks' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_running_tasks_count" {
  sql = <<-EOQ
    select
      running_tasks_count as value,
      'Running Tasks' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_active_services_count" {
  sql = <<-EOQ
    select
      active_services_count as value,
      'Active Services' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_overview" {
  sql = <<-EOQ
    select
      cluster_name as "Name",
      region as "Region",
      account_id as "Account ID",
      cluster_arn as "ARN"
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ecs_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      cluster_arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_ecs_cluster_relationships_graph" {
  sql = <<-EOQ
    with esc_cluster as (
      select
        *
      from
        aws_ecs_cluster
      where
        cluster_arn = $1
    ), list_all_task_definitions as (
        select
          distinct task_definition_arn as task_definition
        from
          aws_ecs_task
        where
          cluster_arn = $1
        union
        select
          distinct task_definition as task_definition
        from
          aws_ecs_service
        where
          cluster_arn = $1
    ), task_definition_launch_type as (
        select
          jsonb_array_elements_text(requires_compatibilities) as launch_type,
          task_definition_arn
        from
          aws_ecs_task_definition as d
        where
          d.task_definition_arn in (select task_definition from list_all_task_definitions)
    )
    select
      null as from_id,
      null as to_id,
      cluster_arn as id,
      cluster_name as title,
      'aws_ecs_cluster' as category,
      jsonb_build_object(
        'ARN', cluster_arn,
        'Status', status,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      esc_cluster

  -- To ECS Launch Type EC2 (node)
    union all
    select
      null as from_id,
      null as to_id,
      'EC2' as id,
      'EC2' as title,
      'launch_type' as category,
      jsonb_build_object(
        'Launch Type', 'EC2'
      ) as properties
    from
      esc_cluster
    where
      'EC2' in (select launch_type from task_definition_launch_type)

    -- To ECS Launch Type EC2 (edge)
    union all
    select
      $1 as from_id,
      'EC2' as to_id,
      null as id,
      'launch type' as title,
      'ecs_cluster_to_launch_type' as category,
      jsonb_build_object(
        'Launch Type', 'EC2'
      ) as properties
    from
      esc_cluster
    where
      'EC2' in (select launch_type from task_definition_launch_type)

    -- To ECS Launch Type FARGATE (node)
    union all
    select
      null as from_id,
      null as to_id,
      'FARGATE' as id,
      'FARGATE' as title,
      'launch_type' as category,
      jsonb_build_object(
        'Launch Type', 'FARGATE'
      ) as properties
    from
      esc_cluster
    where
      'FARGATE' in (select launch_type from task_definition_launch_type)

    -- To ECS Launch Type FARGATE (edge)
    union all
    select
      $1 as from_id,
      'FARGATE' as to_id,
      null as id,
      'launch type' as title,
      'ecs_cluster_to_launch_type' as category,
      jsonb_build_object(
        'Launch Type', 'FARGATE'
      ) as properties
    from
      esc_cluster
    where
      'FARGATE' in (select launch_type from task_definition_launch_type)

   -- To ECS External Launch Type (node)
    union all
    select
      null as from_id,
      null as to_id,
      'EXTERNAL' as id,
      'EXTERNAL' as title,
      'launch_type' as category,
      jsonb_build_object(
        'Launch Type', 'EXTERNAL'
      ) as properties
    from
      esc_cluster
     where
      'EXTERNAL' in (select launch_type from task_definition_launch_type)

    -- To ECS Fargate Launch Type  (edge)
    union all
    select
      $1 as from_id,
      'EXTERNAL' as to_id,
      null as id,
      'launch type' as title,
      'ecs_cluster_to_launch_type' as category,
      jsonb_build_object(
        'Launch Type', 'EXTERNAL'
      ) as properties
    from
      esc_cluster
    where
      'EXTERNAL' in (select launch_type from task_definition_launch_type)

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
      d.task_definition_arn in (select distinct task_definition from list_all_task_definitions )

    -- To ECS task definitions (edge)
    union all
    select
      jsonb_array_elements_text(requires_compatibilities) as from_id,
      d.task_definition_arn as to_id,
      null as id,
      'task defintion' as title,
      'launch_type_to_ecs_task_definition' as category,
      jsonb_build_object(
        'ARN', d.task_definition_arn,
        'Account ID', d.account_id,
        'Region', d.region
      ) as properties
    from
      aws_ecs_task_definition as d
    where
      d.task_definition_arn in (select task_definition from list_all_task_definitions )

    -- To ECS services  (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.arn as id,
      s.service_name as title,
      'aws_ecs_service' as category,
      jsonb_build_object(
        'ARN', s.arn,
        'launch_type', s.launch_type,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_service as s
    where
      s.cluster_arn = $1

    -- To ECS services  (edge)
    union all
    select
      s.task_definition as from_id,
      s.arn as to_id,
      null as id,
      'service' as title,
      'ecs_task_definition_to_ecs_service' as category,
      jsonb_build_object(
        'ARN', s.arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_service as s
    where
      s.cluster_arn = $1

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
      aws_ecs_container_instance as i
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id
    where
      i.cluster_arn = $1

    -- To ECS conatiner instances (edge)
    union all
    select
      s.arn as from_id,
      i.arn as to_id,
      null as id,
      'uses' as title,
      'ecs_service_to_ecs_container_insatnce' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ecs_container_instance as i
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id
      left join aws_ecs_service as s on s.cluster_arn = i.cluster_arn
    where
      s.launch_type = 'EC2'
      and i.cluster_arn = $1

     -- To VPC Subnet (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.subnet_arn as id,
      s.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'Subnet ID', s.subnet_id,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_container_instance as i
      right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id
      right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
    where
      i.cluster_arn  = $1

    -- To VPC Subnet  (edge)
    union all
    select
      i.arn as from_id,
      s.subnet_arn as to_id,
      null as id,
      'subnet' as title,
      'ecs_container_instance_to_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_container_instance as i
      right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id
      right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
    where
      i.cluster_arn  = $1

    -- To VPC  (node)
    union all
    select
      null as from_id,
      null as to_id,
      v.vpc_id as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_ecs_container_instance as i
      right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id
      right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
      right join aws_vpc as v on v.vpc_id = s.vpc_id
    where
      i.cluster_arn  = $1

    -- To VPC  (edge)
    union all
    select
      s.subnet_arn as from_id,
      v.vpc_id as to_id,
      null as id,
      'vpc' as title,
      'vpc_subnet_to_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_ecs_container_instance as i
      right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id
      right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
      right join aws_vpc as v on v.vpc_id = s.vpc_id
    where
      i.cluster_arn  = $1

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
      aws_ecs_service as s
      left join aws_iam_role as r on r.arn = s.role_arn
    where
      s.cluster_arn = $1

    -- To ECS services role (edge)
    union all
    select
      s.arn as from_id,
      s.role_arn as to_id,
      null as id,
      'assumes' as title,
      'aws_ecs_service_to_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Create Date', r.create_date,
        'Account ID', r.account_id
      ) as properties
    from
      aws_ecs_service as s
      left join aws_iam_role as r on r.arn = s.role_arn
    where
      s.cluster_arn = $1

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
      aws_ecs_service as s,
      jsonb_array_elements(load_balancers) as l
      left join aws_ec2_target_group as t on t.target_group_arn = l ->> 'TargetGroupArn'
    where
      s.cluster_arn = $1

    -- To ECS services load balancing  (edge)
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
      aws_ecs_service as s,
      jsonb_array_elements(load_balancers) as l
      left join aws_ec2_target_group as t on t.target_group_arn = l ->> 'TargetGroupArn'
    where
      s.cluster_arn = $1

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
      aws_ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
    where
      e.network_configuration is not null
      and e.cluster_arn = $1

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
      aws_ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
    where
      e.network_configuration is not null
      and e.cluster_arn = $1

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
      aws_ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
      ,aws_vpc as v
    where
      e.network_configuration is not null
      and e.cluster_arn = $1
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
      aws_ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
      ,aws_vpc as v
    where
      e.network_configuration is not null
      and e.cluster_arn = $1
       and v.vpc_id = sb.vpc_id

  EOQ

  param "arn" {}
}
