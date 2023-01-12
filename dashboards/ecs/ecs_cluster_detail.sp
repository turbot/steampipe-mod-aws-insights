dashboard "ecs_cluster_detail" {

  title         = "AWS ECS Cluster Detail"
  documentation = file("./dashboards/ecs/docs/ecs_cluster_detail.md")

  tags = merge(local.ecs_common_tags, {
    type = "Detail"
  })

  input "ecs_cluster_arn" {
    title = "Select a cluster:"
    query = query.ecs_cluster_input
    width = 4
  }

  container {

    card {
      query = query.ecs_cluster_status
      width = 2
      args  = [self.input.ecs_cluster_arn.value]
    }

    card {
      query = query.ecs_cluster_registered_container_instances_count
      width = 2
      args  = [self.input.ecs_cluster_arn.value]
    }

    card {
      query = query.ecs_cluster_active_services_count
      width = 2
      args  = [self.input.ecs_cluster_arn.value]
    }

    card {
      query = query.ecs_cluster_running_tasks_count
      width = 2
      args  = [self.input.ecs_cluster_arn.value]
    }

    card {
      query = query.ecs_cluster_pending_tasks_count
      width = 2
      args  = [self.input.ecs_cluster_arn.value]
    }

    card {
      query = query.ecs_cluster_container_insights_enabled
      width = 2
      args  = [self.input.ecs_cluster_arn.value]
    }

  }

  with "ecs_container_instances_for_ecs_cluster" {
    query = query.ecs_container_instances_for_ecs_cluster
    args  = [self.input.ecs_cluster_arn.value]
  }

  with "ecs_services_for_ecs_cluster" {
    query = query.ecs_services_for_ecs_cluster
    args  = [self.input.ecs_cluster_arn.value]
  }

  with "ecs_task_definitions_for_ecs_cluster" {
    query = query.ecs_task_definitions_for_ecs_cluster
    args  = [self.input.ecs_cluster_arn.value]
  }

  with "vpc_subnets_for_ecs_cluster" {
    query = query.vpc_subnets_for_ecs_cluster
    args  = [self.input.ecs_cluster_arn.value]
  }

  with "vpc_vpcs_for_ecs_cluster" {
    query = query.vpc_vpcs_for_ecs_cluster
    args  = [self.input.ecs_cluster_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.ecs_cluster
        args = {
          ecs_cluster_arns = [self.input.ecs_cluster_arn.value]
        }
      }

      node {
        base = node.ecs_cluster_ec2_launch_type
        args = {
          ecs_cluster_arns = [self.input.ecs_cluster_arn.value]
        }
      }

      node {
        base = node.ecs_cluster_external_launch_type
        args = {
          ecs_cluster_arns = [self.input.ecs_cluster_arn.value]
        }
      }

      node {
        base = node.ecs_cluster_fargate_launch_type
        args = {
          ecs_cluster_arns = [self.input.ecs_cluster_arn.value]
        }
      }

      node {
        base = node.ecs_container_instance
        args = {
          ecs_container_instance_arns = with.ecs_container_instances_for_ecs_cluster.rows[*].container_instance_arn
        }
      }

      node {
        base = node.ecs_service
        args = {
          ecs_service_arns = with.ecs_services_for_ecs_cluster.rows[*].service_arn
        }
      }

      node {
        base = node.ecs_task_definition
        args = {
          ecs_task_definition_arns = with.ecs_task_definitions_for_ecs_cluster.rows[*].task_definition_arn
        }
      }

      node {
        base = node.ecs_service
        args = {
          ecs_service_arns = with.ecs_services_for_ecs_cluster.rows[*].service_arn
        }
      }

      node {
        base = node.ecs_task_definition
        args = {
          ecs_task_definition_arns = with.ecs_task_definitions_for_ecs_cluster.rows[*].task_definition_arn
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_ecs_cluster.rows[*].subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_ecs_cluster.rows[*].vpc_id
        }
      }

      edge {
        base = edge.ecs_cluster_to_ecs_cluster_ec2_launch_type
        args = {
          ecs_cluster_arns = [self.input.ecs_cluster_arn.value]
        }
      }

      edge {
        base = edge.ecs_cluster_to_ecs_cluster_external_launch_type
        args = {
          ecs_cluster_arns = [self.input.ecs_cluster_arn.value]
        }
      }

      edge {
        base = edge.ecs_cluster_to_ecs_cluster_fargate_launch_type
        args = {
          ecs_cluster_arns = [self.input.ecs_cluster_arn.value]
        }
      }

      edge {
        base = edge.ecs_cluster_to_ecs_container_instance
        args = {
          ecs_cluster_arns = [self.input.ecs_cluster_arn.value]
        }
      }

      edge {
        base = edge.ecs_cluster_to_ecs_task_definition
        args = {
          ecs_cluster_arns = [self.input.ecs_cluster_arn.value]
        }
      }

      edge {
        base = edge.ecs_container_instance_to_vpc_subnet
        args = {
          ecs_container_instance_arns = with.ecs_container_instances_for_ecs_cluster.rows[*].container_instance_arn
        }
      }

      edge {
        base = edge.ecs_task_definition_to_ecs_service
        args = {
          ecs_task_definition_arns = with.ecs_task_definitions_for_ecs_cluster.rows[*].task_definition_arn
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_ecs_cluster.rows[*].subnet_id
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
        query = query.ecs_cluster_overview
        args  = [self.input.ecs_cluster_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.ecs_cluster_tags
        args  = [self.input.ecs_cluster_arn.value]

      }
    }

    container {
      width = 6

      table {
        title = "Registered Container Instances"
        query = query.ecs_cluster_container_instances
        args  = [self.input.ecs_cluster_arn.value]

        column "Instance ARN" {
          display = "none"
        }

        column "EC2 Instance ID" {
          href = "${dashboard.ec2_instance_detail.url_path}?input.instance_arn={{.'Instance ARN' | @uri}}"
        }

      }

      table {
        title = "Statistics"
        query = query.ecs_cluster_statistics
        args  = [self.input.ecs_cluster_arn.value]

      }


    }

  }
}

# Input queries

query "ecs_cluster_input" {
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

# With queries

query "ecs_container_instances_for_ecs_cluster" {
  sql = <<-EOQ
    select
      i.arn as container_instance_arn
    from
      aws_ecs_container_instance as i
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id
    where
      i.arn is not null
      and i.cluster_arn = $1;
  EOQ
}

query "ecs_services_for_ecs_cluster" {
  sql = <<-EOQ
    select
      s.arn as service_arn
    from
      aws_ecs_service as s
    where
      s.cluster_arn = $1;
  EOQ
}

query "ecs_task_definitions_for_ecs_cluster" {
  sql = <<-EOQ
    with list_all_task_definitions as (
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
    )
    select
      d.task_definition_arn as task_definition_arn
    from
      aws_ecs_task_definition as d
    where
      d.task_definition_arn in (
        select
          distinct task_definition
        from
          list_all_task_definitions
      );
  EOQ
}

query "vpc_subnets_for_ecs_cluster" {
  sql = <<-EOQ
    select
      s.subnet_id as subnet_id
    from
      aws_ecs_container_instance as i
      right join
        aws_ec2_instance as c
        on c.instance_id = i.ec2_instance_id
      right join
        aws_vpc_subnet as s
        on s.subnet_id = c.subnet_id
    where
      i.cluster_arn = $1;
  EOQ
}

query "vpc_vpcs_for_ecs_cluster" {
  sql = <<-EOQ
    select
    v.vpc_id as vpc_id
  from
    aws_ecs_container_instance as i
    right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id
    right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
    right join aws_vpc as v on v.vpc_id = s.vpc_id
  where
    v.vpc_id is not null
    and i.cluster_arn = $1;
  EOQ
}

# Card queries

query "ecs_cluster_status" {
  sql = <<-EOQ
    select
      initcap(status) as value,
      'Status' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ
}

query "ecs_cluster_registered_container_instances_count" {
  sql = <<-EOQ
    select
      registered_container_instances_count as value,
      'Registered Container Instances' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ
}

query "ecs_cluster_pending_tasks_count" {
  sql = <<-EOQ
    select
      pending_tasks_count as value,
      'Pending Tasks' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ
}

query "ecs_cluster_running_tasks_count" {
  sql = <<-EOQ
    select
      running_tasks_count as value,
      'Running Tasks' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ
}

query "ecs_cluster_active_services_count" {
  sql = <<-EOQ
    select
      active_services_count as value,
      'Active Services' as label
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ
}

query "ecs_cluster_container_insights_enabled" {
  sql = <<-EOQ
    select
      'Container Insights' as label,
      case when s ->> 'Name' = 'containerInsights' and s ->> 'Value' = 'enabled' then 'Enabled' else 'Disabled' end as value,
      case when s ->> 'Name' = 'containerInsights' and s ->> 'Value' = 'enabled' then 'ok' else 'alert' end as type
    from
      aws_ecs_cluster as c,
      jsonb_array_elements(settings) as s
    where
      cluster_arn = $1;
  EOQ
}

# Other detail page queries

query "ecs_cluster_overview" {
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
}

query "ecs_cluster_tags" {
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
}

query "ecs_cluster_statistics" {
  sql = <<-EOQ
    select
      s ->> 'Name' as "Name",
      s ->> 'Value' as "Value"
    from
      aws_ecs_cluster,
      jsonb_array_elements(statistics) as s
    where
      cluster_arn = $1
    order by
      s ->> 'Name';
  EOQ
}

query "ecs_cluster_container_instances" {
  sql = <<-EOQ
    select
      c.ec2_instance_id as "EC2 Instance ID",
      c.registered_at as "Rgeistered At",
      c.arn as "ARN",
      i.arn as "Instance ARN"
    from
      aws_ecs_container_instance as c
      left join aws_ec2_instance as i on c.ec2_instance_id = i.instance_id
    where
      cluster_arn = $1
    order by
      ec2_instance_id;
  EOQ
}
