dashboard "aws_ecs_service_detail" {

  title         = "AWS ECS Service Detail"
  documentation = file("./dashboards/ecs/docs/ecs_service_detail.md")

  tags = merge(local.ecs_common_tags, {
    type = "Detail"
  })

  input "service_arn" {
    title = "Select a service:"
    query = query.aws_ecs_service_input
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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"


      nodes = [
        node.aws_ecs_service_node,
        node.aws_ecs_service_to_ecs_task_node,
        node.aws_ecs_service_to_ec2_target_group_node,
        node.aws_ecs_service_from_ecs_cluster_node,
        node.aws_ecs_service_to_ecs_container_instance_node,
        node.aws_ecs_service_to_vpc_security_group_node,
        node.aws_ecs_service_to_vpc_subnet_node,
        node.aws_ecs_service_vpc_subnet_to_vpc_node,
        node.aws_ecs_service_to_ecs_task_definition_node
      ]

      edges = [
        edge.aws_ecs_service_to_ecs_task_edge,
        edge.aws_ecs_service_to_iam_role_edge,
        edge.aws_ecs_service_to_ec2_target_group_edge,
        edge.aws_ecs_service_from_ecs_cluster_edge,
        edge.aws_ecs_service_to_ecs_container_instance_edge,
        edge.aws_ecs_service_to_vpc_security_group_edge,
        edge.aws_ecs_service_to_vpc_subnet_edge,
        edge.aws_ecs_service_vpc_subnet_to_vpc_edge,
        edge.aws_ecs_service_to_ecs_task_definition_edge
      ]

      args = {
        arn = self.input.service_arn.value
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

node "aws_ecs_service_node" {
  category = category.aws_ecs_service

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ecs_service
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_service_to_ecs_task_node" {
  category = category.aws_ecs_task

  sql = <<-EOQ
    select
      t.task_arn as id,
      concat(split_part(t.task_arn, '/', 2),'/' ,split_part(t.task_arn, '/', 3)) as title,
      jsonb_build_object(
        'ARN', t.task_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_ecs_task as t,
      aws_ecs_service as s
    where
      s.arn = $1
      and t.service_name = s.service_name
      and t.region = s.region;
  EOQ

  param "arn" {}
}

edge "aws_ecs_service_to_ecs_task_edge" {
  title = "task"

  sql = <<-EOQ
    select
      $1 as from_id,
      t.task_arn as to_id
    from
      aws_ecs_task as t,
      aws_ecs_service as s
    where
      s.arn = $1
      and t.service_name = s.service_name
      and t.region = s.region;
  EOQ

  param "arn" {}
}

node "aws_ecs_service_to_iam_role_node" {
  category = category.aws_iam_role

  sql = <<-EOQ
    select
      r.arn as id,
      r.title as title,
      jsonb_build_object(
        'ARN', r.arn,
        'Create Date', r.create_date,
        'Account ID', r.account_id
      ) as properties
    from
      aws_ecs_service as s
      left join aws_iam_role as r on r.arn = s.role_arn and s.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_service_to_iam_role_edge" {
  title = "assumes"

  sql = <<-EOQ
    select
      s.arn as from_id,
      s.role_arn as to_id
    from
      aws_ecs_service as s
      left join aws_iam_role as r on r.arn = s.role_arn and s.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_service_to_ec2_target_group_node" {
  category = category.aws_ec2_target_group

  sql = <<-EOQ
    select
      t.target_group_arn as id,
      t.title as title,
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
      s.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_service_to_ec2_target_group_edge" {
  title = "target group"

  sql = <<-EOQ
    select
      s.arn as from_id,
      l ->> 'TargetGroupArn' as to_id
    from
      aws_ecs_service as s,
      jsonb_array_elements(load_balancers) as l
      left join aws_ec2_target_group as t on t.target_group_arn = l ->> 'TargetGroupArn'
    where
      s.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_service_from_ecs_cluster_node" {
  category = category.aws_ecs_cluster

  sql = <<-EOQ
    select
      c.cluster_arn as id,
      c.title as title,
      jsonb_build_object(
        'ARN', c.cluster_arn,
        'Status', c.status,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_ecs_service as s
      left join aws_ecs_cluster as c on s.cluster_arn = c.cluster_arn and s.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_service_from_ecs_cluster_edge" {
  title = "ecs cluster"

  sql = <<-EOQ
    select
      c.cluster_arn as from_id,
      s.arn to_id
    from
      aws_ecs_service as s
      left join aws_ecs_cluster as c on s.cluster_arn = c.cluster_arn and s.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_service_to_ecs_container_instance_node" {
  category = category.aws_ecs_container_instance

  sql = <<-EOQ
    select
      i.arn as id,
      e.title as title,
      jsonb_build_object(
        'ARN', i.arn,
        'Instance ID', i.ec2_instance_id,
        'Status', i.status,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ecs_service as s
      left join aws_ecs_container_instance as i on s.cluster_arn = i.cluster_arn
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id
    where
      s.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_service_to_ecs_container_instance_edge" {
  title = "container instance"

  sql = <<-EOQ
    select
      s.arn as from_id,
      i.arn as to_id
    from
      aws_ecs_service as s
      left join aws_ecs_container_instance as i on s.cluster_arn = i.cluster_arn
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id
    where
      s.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_service_to_vpc_security_group_node" {
  category = category.aws_vpc_security_group

  sql = <<-EOQ
    select
      sg.group_id as id,
      sg.title as title,
      jsonb_build_object(
        'Group ID', sg.group_id,
        'Description', sg.description,
        'ARN', sg.arn,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      aws_ecs_service as e,
      jsonb_array_elements_text(e.network_configuration -> 'AwsvpcConfiguration' -> 'SecurityGroups') as s
      left join aws_vpc_security_group as sg on sg.group_id = s
    where
      e.arn = $1
      and e.network_configuration is not null;
  EOQ

  param "arn" {}
}

edge "aws_ecs_service_to_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      e.arn as from_id,
      s as to_id
    from
      aws_ecs_service as e,
      jsonb_array_elements_text(e.network_configuration -> 'AwsvpcConfiguration' -> 'SecurityGroups') as s
    where
      e.arn = $1
      and e.network_configuration is not null;
  EOQ

  param "arn" {}
}


node "aws_ecs_service_to_vpc_subnet_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      sb.subnet_id as id,
      sb.title as title,
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
      e.arn = $1
      and e.network_configuration is not null;
  EOQ

  param "arn" {}
}

edge "aws_ecs_service_to_vpc_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      coalesce(sg, e.arn) as from_id,
      s as to_id
    from
      aws_ecs_service as e,
      jsonb_array_elements_text(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s,
      jsonb_array_elements_text(e.network_configuration -> 'AwsvpcConfiguration' -> 'SecurityGroups') as sg
    where
      e.arn = $1
      and e.network_configuration is not null;
  EOQ

  param "arn" {}
}

node "aws_ecs_service_vpc_subnet_to_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      v.arn as id,
      v.title as title,
      jsonb_build_object(
        'ARN', v.arn,
        'VPC ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""'),
      aws_vpc as v
    where
      e.arn = $1
      and e.network_configuration is not null
      and v.vpc_id = sb.vpc_id;
  EOQ

  param "arn" {}
}

edge "aws_ecs_service_vpc_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      sb.subnet_id as from_id,
      v.arn as to_id
    from
      aws_ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""'),
      aws_vpc as v
    where
      e.arn = $1
      and e.network_configuration is not null
      and v.vpc_id = sb.vpc_id;
  EOQ

  param "arn" {}
}

node "aws_ecs_service_to_ecs_task_definition_node" {
  category = category.aws_ecs_task_definition

  sql = <<-EOQ
    select
      d.task_definition_arn as id,
      d.title as title,
      jsonb_build_object(
        'ARN', d.task_definition_arn,
        'CPU', d.cpu,
        'Status', d.status,
        'Memory', d.memory,
        'Registered At', d.registered_at
      ) as properties
    from
      aws_ecs_task_definition as d,
      aws_ecs_service as s
    where
      d.task_definition_arn = s.task_definition
      and s.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_service_to_ecs_task_definition_edge" {
  title = "task defintion"

  sql = <<-EOQ
    select
      $1 as to_id,
      d.task_definition_arn as from_id
    from
      aws_ecs_task_definition as d,
      aws_ecs_service as s
    where
      d.task_definition_arn = s.task_definition
      and s.arn = $1;
  EOQ

  param "arn" {}
}
