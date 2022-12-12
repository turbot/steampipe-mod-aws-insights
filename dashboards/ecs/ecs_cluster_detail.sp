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
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.ecs_cluster_registered_container_instances_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.ecs_cluster_active_services_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.ecs_cluster_running_tasks_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.ecs_cluster_pending_tasks_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.ecs_cluster_container_insights_enabled
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "ecs_container_instances" {
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

        args = [self.input.ecs_cluster_arn.value]
      }

      with "ecs_services" {
        sql = <<-EOQ
          select
            s.arn as service_arn
          from
            aws_ecs_service as s
          where
            s.cluster_arn = $1;
        EOQ

        args = [self.input.ecs_cluster_arn.value]
      }

      with "ecs_task_definitions" {
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

        args = [self.input.ecs_cluster_arn.value]
      }

      with "vpc_subnets" {
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

        args = [self.input.ecs_cluster_arn.value]
      }

      with "vpc_vpcs" {
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

        args = [self.input.ecs_cluster_arn.value]
      }

      nodes = [
        node.ecs_cluster,
        node.ecs_cluster_ec2_launch_type,
        node.ecs_cluster_external_launch_type,
        node.ecs_cluster_fargate_launch_type,
        node.ecs_container_instance,
        node.ecs_service,
        node.ecs_task_definition,
        node.vpc_subnet,
        node.vpc_vpc
      ]

      edges = [
        edge.ecs_cluster_to_ecs_cluster_ec2_launch_type,
        edge.ecs_cluster_to_ecs_cluster_external_launch_type,
        edge.ecs_cluster_to_ecs_cluster_fargate_launch_type,
        edge.ecs_cluster_to_ecs_container_instance,
        edge.ecs_cluster_to_ecs_task_definition,
        edge.ecs_container_instance_to_vpc_subnet,
        edge.ecs_task_definition_to_ecs_service,
        edge.vpc_subnet_to_vpc_vpc
      ]

      args = {
        ecs_cluster_arns            = [self.input.ecs_cluster_arn.value]
        ecs_container_instance_arns = with.ecs_container_instances.rows[*].container_instance_arn
        ecs_service_arns            = with.ecs_services.rows[*].service_arn
        ecs_task_definition_arns    = with.ecs_task_definitions.rows[*].task_definition_arn
        vpc_subnet_ids              = with.vpc_subnets.rows[*].subnet_id
        vpc_vpc_ids                 = with.vpc_vpcs.rows[*].vpc_id
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
        args = {
          arn = self.input.ecs_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.ecs_cluster_tags
        args = {
          arn = self.input.ecs_cluster_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Registered Container Instances"
        query = query.ecs_cluster_container_instances
        args = {
          arn = self.input.ecs_cluster_arn.value
        }

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
        args = {
          arn = self.input.ecs_cluster_arn.value
        }

      }


    }

  }
}

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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
}

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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
}

node "ecs_cluster_node" {
  category = category.ecs_cluster

  sql = <<-EOQ
    select
      cluster_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', cluster_arn,
        'Status', status,
        'Account ID', account_id,
        'Region', region,
        'Active Services Count', active_services_count,
        'Running Tasks Count', running_tasks_count
      ) as properties
    from
      aws_ecs_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}
