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
      width = 3
      args  = [self.input.service_arn.value]
    }

    card {
      query = query.ecs_service_launch_type
      width = 3
      args  = [self.input.service_arn.value]
    }

  }

  with "ec2_target_groups_for_ecs_service" {
    query = query.ec2_target_groups_for_ecs_service
    args  = [self.input.service_arn.value]
  }

  with "ecs_clusters_for_ecs_service" {
    query = query.ecs_clusters_for_ecs_service
    args  = [self.input.service_arn.value]
  }

  with "ecs_container_instances_for_ecs_service" {
    query = query.ecs_container_instances_for_ecs_service
    args  = [self.input.service_arn.value]
  }

  with "ecs_tasks_for_ecs_service" {
    query = query.ecs_tasks_for_ecs_service
    args  = [self.input.service_arn.value]
  }

  with "ecs_task_definitions_for_ecs_service" {
    query = query.ecs_task_definitions_for_ecs_service
    args  = [self.input.service_arn.value]
  }

  with "iam_roles_for_ecs_service" {
    query = query.iam_roles_for_ecs_service
    args  = [self.input.service_arn.value]
  }

  with "vpc_security_groups_for_ecs_service" {
    query = query.vpc_security_groups_for_ecs_service
    args  = [self.input.service_arn.value]
  }

  with "vpc_subnets_for_ecs_service" {
    query = query.vpc_subnets_for_ecs_service
    args  = [self.input.service_arn.value]
  }

  with "vpc_vpcs_for_ecs_service" {
    query = query.vpc_vpcs_for_ecs_service
    args  = [self.input.service_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.ec2_target_group
        args = {
          ec2_target_group_arns = with.ec2_target_groups_for_ecs_service.rows[*].target_group_arn
        }
      }

      node {
        base = node.ecs_cluster
        args = {
          ecs_cluster_arns = with.ecs_clusters_for_ecs_service.rows[*].cluster_arn
        }
      }

      node {
        base = node.ecs_container_instance
        args = {
          ecs_container_instance_arns = with.ecs_container_instances_for_ecs_service.rows[*].container_instance_arn
        }
      }

      node {
        base = node.ecs_service
        args = {
          ecs_service_arns = [self.input.service_arn.value]
        }
      }


      node {
        base = node.ecs_task
        args = {
          ecs_task_arns = with.ecs_tasks_for_ecs_service.rows[*].task_arn
        }
      }

      node {
        base = node.ecs_task_definition
        args = {
          ecs_task_definition_arns = with.ecs_task_definitions_for_ecs_service.rows[*].task_definition_arn
        }
      }

      node {
        base = node.iam_role
        args = {
          iam_role_arns = with.iam_roles_for_ecs_service.rows[*].role_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_ecs_service.rows[*].group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_ecs_service.rows[*].subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_ecs_service.rows[*].vpc_id
        }
      }

      edge {
        base = edge.ecs_cluster_to_ecs_service
        args = {
          ecs_cluster_arns = with.ecs_clusters_for_ecs_service.rows[*].cluster_arn
        }
      }

      edge {
        base = edge.ecs_service_to_ec2_target_group
        args = {
          ecs_service_arns = [self.input.service_arn.value]
        }
      }

      edge {
        base = edge.ecs_service_to_ecs_container_instance
        args = {
          ecs_service_arns = [self.input.service_arn.value]
        }
      }

      edge {
        base = edge.ecs_task_definition_to_ecs_task
        args = {
          ecs_task_definition_arns = with.ecs_task_definitions_for_ecs_service.rows[*].task_definition_arn
        }
      }

      edge {
        base = edge.ecs_service_to_ecs_task_definition
        args = {
          ecs_service_arns = [self.input.service_arn.value]
        }
      }

      edge {
        base = edge.ecs_service_to_iam_role
        args = {
          ecs_service_arns = [self.input.service_arn.value]
        }
      }

      edge {
        base = edge.ecs_service_to_vpc_security_group
        args = {
          ecs_service_arns = [self.input.service_arn.value]
        }
      }

      edge {
        base = edge.ecs_service_to_vpc_subnet
        args = {
          ecs_service_arns = [self.input.service_arn.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_ecs_service.rows[*].subnet_id
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
        query = query.ecs_service_overview
        args  = [self.input.service_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.ecs_service_tags
        args  = [self.input.service_arn.value]

      }
    }

    container {
      width = 6

      table {
        title = "Tasks"
        query = query.ecs_service_tasks
        args  = [self.input.service_arn.value]
      }

    }

  }
}

# Input queries

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

# With queries

query "ec2_target_groups_for_ecs_service" {
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
}

query "ecs_clusters_for_ecs_service" {
  sql = <<-EOQ
    select
      c.cluster_arn as cluster_arn
    from
      aws_ecs_service as s
      left join aws_ecs_cluster as c on s.cluster_arn = c.cluster_arn and s.arn = $1
    where
      c.cluster_arn is not null
  EOQ
}

query "ecs_container_instances_for_ecs_service" {
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
}

query "ecs_tasks_for_ecs_service" {
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
}

query "ecs_task_definitions_for_ecs_service" {
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
}

query "iam_roles_for_ecs_service" {
  sql = <<-EOQ
    select
      r.arn as role_arn
    from
      aws_ecs_service as s
      left join aws_iam_role as r on r.arn = s.role_arn and s.arn = $1
    where
      r.arn is not null
  EOQ
}

query "vpc_security_groups_for_ecs_service" {
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
}

query "vpc_subnets_for_ecs_service" {
  sql = <<-EOQ
    select
      sb.subnet_id as subnet_id
    from
      aws_ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
    where
      e.network_configuration is not null
      and e.arn = $1;
  EOQ
}

query "vpc_vpcs_for_ecs_service" {
  sql = <<-EOQ
    select
      sb.vpc_id
    from
      aws_ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""')
    where
      e.network_configuration is not null
      and e.arn = $1;
  EOQ
}

# Card queries

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
}

# Other detail page queries

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
}
