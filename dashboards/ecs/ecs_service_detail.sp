dashboard "ecs_service_detail" {

  title         = "AWS ECS Service Detail"
  documentation = file("./dashboards/ecs/docs/ecs_service_detail.md")

  tags = merge(local.ecs_common_tags, {
    type = "Detail"
  })

  input "service_arn" {
    title = "Select a service:"
    query = query.ecs_service_input
    width = 4
  }

  container {

    card {
      query = query.ecs_service_status
      width = 2
      args = {
        arn = self.input.service_arn.value
      }
    }

    card {
      query = query.ecs_service_launch_type
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

      with "ec2_target_groups" {
        sql = <<-EOQ
          select
            t.target_group_arn as target_group_arn
          from
            aws_ecs_service as s,
            jsonb_array_elements(load_balancers) as l
            left join aws_ec2_target_group as t on t.target_group_arn = l ->> 'TargetGroupArn'
          where
            s.arn = $1;
        EOQ

        args = [self.input.service_arn.value]
      }

      with "ecs_clusters" {
        sql = <<-EOQ
          select
            c.cluster_arn as cluster_arn
          from
            aws_ecs_service as s
            left join aws_ecs_cluster as c on s.cluster_arn = c.cluster_arn and s.arn = $1
          where
            c.cluster_arn is not null
        EOQ

        args = [self.input.service_arn.value]
      }

      with "ecs_container_instances" {
        sql = <<-EOQ
          select
            i.arn as container_instance_arn
          from
            aws_ecs_service as s
            left join aws_ecs_container_instance as i on s.cluster_arn = i.cluster_arn
            left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id
          where
            i.arn  is not null
            and s.arn = $1;
        EOQ

        args = [self.input.service_arn.value]
      }

      with "ecs_task_definitions" {
        sql = <<-EOQ
          select
            d.task_definition_arn as task_definition_arn
          from
            aws_ecs_task_definition as d,
            aws_ecs_service as s
          where
            d.task_definition_arn = s.task_definition
            and s.arn = $1;
        EOQ

        args = [self.input.service_arn.value]
      }

      with "ecs_tasks" {
        sql = <<-EOQ
          select
            t.task_arn as task_arn
          from
            aws_ecs_task as t,
            aws_ecs_service as s
          where
            s.arn = $1
            and t.service_name = s.service_name
            and t.region = s.region;
        EOQ

        args = [self.input.service_arn.value]
      }

      with "iam_roles" {
        sql = <<-EOQ
          select
            r.arn as role_arn
          from
            aws_ecs_service as s
            left join aws_iam_role as r on r.arn = s.role_arn and s.arn = $1
          where
            r.arn is not null
        EOQ

        args = [self.input.service_arn.value]
      }

      with "vpc_security_groups" {
        sql = <<-EOQ
          select
            sg.group_id as group_id
          from
            aws_ecs_service as e,
            jsonb_array_elements_text(e.network_configuration -> 'AwsvpcConfiguration' -> 'SecurityGroups') as s
            left join aws_vpc_security_group as sg on sg.group_id = s
          where
            e.arn = $1
            and e.network_configuration is not null;
        EOQ

        args = [self.input.service_arn.value]
      }

      with "vpc_subnets" {
        sql = <<-EOQ
          select
            sb.subnet_id as subnet_id
          from
            aws_ecs_service as e,
            jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
            left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
          where
            e.arn = $1
            and e.network_configuration is not null;
        EOQ

        args = [self.input.service_arn.value]
      }

      with "vpc_vpcs" {
        sql = <<-EOQ
         select
          v.arn as vpc_arn
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

        args = [self.input.service_arn.value]
      }

      nodes = [
        node.ec2_target_group,
        node.ecs_cluster,
        node.ecs_container_instance,
        node.ecs_service,
        node.ecs_task_definition,
        node.ecs_task,
        node.iam_role,
        node.vpc_security_group,
        node.vpc_subnet,
        node.vpc_vpc,
      ]

      edges = [
        edge.ecs_cluster_to_ecs_service,
        edge.ecs_service_to_ec2_target_group,
        edge.ecs_service_to_ecs_container_instance,
        edge.ecs_service_to_ecs_task_definition,
        edge.ecs_service_to_ecs_task,
        edge.ecs_service_to_iam_role,
        edge.ecs_service_to_vpc_security_group,
        edge.ecs_service_to_vpc_subnet,
        edge.vpc_subnet_to_vpc_vpc,
      ]

      args = {
        ec2_target_group_arns       = with.ec2_target_groups.rows[*].target_group_arn
        ecs_cluster_arns            = with.ecs_clusters.rows[*].cluster_arn
        ecs_container_instance_arns = with.ecs_container_instances.rows[*].container_instance_arn
        ecs_service_arns            = [self.input.service_arn.value]
        ecs_task_arns               = with.ecs_tasks.rows[*].task_arn
        ecs_task_definition_arns    = with.ecs_task_definitions.rows[*].task_definition_arn
        iam_role_arns               = with.iam_roles.rows[*].role_arn
        vpc_security_group_ids      = with.vpc_security_groups.rows[*].group_id
        vpc_subnet_ids              = with.vpc_subnets.rows[*].subnet_id
        vpc_vpc_ids                 = with.vpc_vpcs.rows[*].vpc_arn
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
        query = query.ecs_service_overview
        args = {
          arn = self.input.service_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.ecs_service_tags
        args = {
          arn = self.input.service_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Tasks"
        query = query.ecs_service_tasks
        args = {
          arn = self.input.service_arn.value
        }
      }

    }

  }
}

query "ecs_service_input" {
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

query "ecs_service_status" {
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

query "ecs_service_launch_type" {
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

query "ecs_service_overview" {
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

query "ecs_service_tasks" {
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

query "ecs_service_tags" {
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
