dashboard "aws_ecs_cluster_detail" {

  title         = "AWS ECS Cluster Detail"
  documentation = file("./dashboards/ecs/docs/ecs_cluster_detail.md")

  tags = merge(local.ecs_common_tags, {
    type = "Detail"
  })

  input "ecs_cluster_arn" {
    title = "Select a cluster:"
    query = query.aws_ecs_cluster_input
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
      query = query.aws_ecs_cluster_active_services_count
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
      query = query.aws_ecs_cluster_pending_tasks_count
      width = 2
      args = {
        arn = self.input.ecs_cluster_arn.value
      }
    }

    card {
      query = query.aws_ecs_cluster_container_insights_enabled
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


      nodes = [
        node.aws_ecs_cluster_node,
        node.aws_ecs_cluster_to_ec2_launch_type_node,
        node.aws_ecs_cluster_to_fargate_launch_type_node,
        node.aws_ecs_cluster_to_external_launch_type_node,
        node.aws_ecs_cluster_to_ecs_task_definition_node,
        node.aws_ecs_cluster_to_ecs_service_node,
        node.aws_ecs_cluster_to_ecs_container_instance_node,
        node.aws_ecs_cluster_ecs_container_instance_to_vpc_subnet_node,
        node.aws_ecs_cluster_vpc_subnet_to_vpc_node,
        node.aws_ecs_cluster_ecs_service_to_vpc_subnet_node,
        node.aws_ecs_cluster_ecs_service_subnet_to_vpc_node
      ]

      edges = [
        edge.aws_ecs_cluster_to_ec2_launch_type_edge,
        edge.aws_ecs_cluster_to_fargate_launch_type_edge,
        edge.aws_ecs_cluster_to_external_launch_type_edge,
        edge.aws_ecs_cluster_to_ecs_task_definition_edge,
        edge.aws_ecs_cluster_to_ecs_service_edge,
        edge.aws_ecs_cluster_to_ecs_container_instance_edge,
        edge.aws_ecs_cluster_ecs_container_instance_to_vpc_subnet_edge,
        edge.aws_ecs_cluster_vpc_subnet_to_vpc_edge,
        edge.aws_ecs_cluster_ecs_service_to_vpc_subnet_edge,
        edge.aws_ecs_cluster_ecs_service_subnet_to_vpc_edge
      ]

      args = {
        arn = self.input.ecs_cluster_arn.value
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

      table {
        title = "Registered Container Instances"
        query = query.aws_ecs_cluster_container_instances
        args = {
          arn = self.input.ecs_cluster_arn.value
        }

        column "Instance ARN" {
          display = "none"
        }

        column "EC2 Instance ID" {
          href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.'Instance ARN' | @uri}}"
        }

      }

      table {
        title = "Statistics"
        query = query.aws_ecs_cluster_statistics
        args = {
          arn = self.input.ecs_cluster_arn.value
        }

      }


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

query "aws_ecs_cluster_container_insights_enabled" {
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

query "aws_ecs_cluster_statistics" {
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

query "aws_ecs_cluster_container_instances" {
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

node "aws_ecs_cluster_node" {
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

node "aws_ecs_cluster_to_ec2_launch_type_node" {
  # category = category.aws_kms_key

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
    ),task_definition_launch_type as (
      select
        jsonb_array_elements_text(requires_compatibilities) as launch_type,
        task_definition_arn
      from
        aws_ecs_task_definition as d
      where
        d.task_definition_arn in (select task_definition from list_all_task_definitions)
    ) select
      'EC2' as id,
      'EC2' as title,
      'ec2_launch_type' as category,
      jsonb_build_object(
        'Launch Type', 'EC2'
      ) as properties
    from
      aws_ecs_cluster
    where
      'EC2' in (
        select
          launch_type
        from
          task_definition_launch_type
      )
      and cluster_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_cluster_to_ec2_launch_type_edge" {
  title = "launch type"

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
    ),task_definition_launch_type as (
      select
        jsonb_array_elements_text(requires_compatibilities) as launch_type,
        task_definition_arn
      from
        aws_ecs_task_definition as d
      where
        d.task_definition_arn in (select task_definition from list_all_task_definitions)
    ) select
        $1 as from_id,
        'EC2' as to_id
      from
        aws_ecs_cluster
      where
        'EC2' in (
          select
            launch_type
          from
            task_definition_launch_type
        )
        and cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_cluster_to_fargate_launch_type_node" {
  # category = category.fargate_launch_type

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
    ),task_definition_launch_type as (
      select
        jsonb_array_elements_text(requires_compatibilities) as launch_type,
        task_definition_arn
      from
        aws_ecs_task_definition as d
      where
        d.task_definition_arn in (select task_definition from list_all_task_definitions)
    ) select
        'FARGATE' as id,
        'FARGATE' as title,
        jsonb_build_object(
          'Launch Type', 'FARGATE'
        ) as properties
      from
        aws_ecs_cluster
      where
        'FARGATE' in (
          select
            launch_type
          from
            task_definition_launch_type
        )
        and cluster_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_cluster_to_fargate_launch_type_edge" {
  title = "launch type"

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
    ),task_definition_launch_type as (
      select
        jsonb_array_elements_text(requires_compatibilities) as launch_type,
        task_definition_arn
      from
        aws_ecs_task_definition as d
      where
        d.task_definition_arn in (select task_definition from list_all_task_definitions)
    ) select
        $1 as from_id,
        'FARGATE' as to_id
      from
        aws_ecs_cluster
      where
        'FARGATE' in (
          select
            launch_type
          from
            task_definition_launch_type
        )
        and cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_cluster_to_external_launch_type_node" {
  # category = category.fargate_launch_type

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
    ),task_definition_launch_type as (
      select
        jsonb_array_elements_text(requires_compatibilities) as launch_type,
        task_definition_arn
      from
        aws_ecs_task_definition as d
      where
        d.task_definition_arn in (select task_definition from list_all_task_definitions)
    ) select
        'EXTERNAL' as id,
        'EXTERNAL' as title,
        jsonb_build_object(
          'Launch Type', 'EXTERNAL'
        ) as properties
      from
        aws_ecs_cluster
      where
        'EXTERNAL' in (
          select
            launch_type
          from
            task_definition_launch_type
        )
        and cluster_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_cluster_to_external_launch_type_edge" {
  title = "launch type"

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
    ),task_definition_launch_type as (
      select
        jsonb_array_elements_text(requires_compatibilities) as launch_type,
        task_definition_arn
      from
        aws_ecs_task_definition as d
      where
        d.task_definition_arn in (select task_definition from list_all_task_definitions)
    ) select
        $1 as from_id,
        'EXTERNAL' as to_id
      from
        aws_ecs_cluster
      where
        'EXTERNAL' in (
          select
            launch_type
          from
            task_definition_launch_type
        )
        and cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_cluster_to_ecs_task_definition_node" {
  category = category.aws_ecs_task_definition

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
      d.task_definition_arn as id,
      d.title as title,
      jsonb_build_object(
        'ARN', d.task_definition_arn,
        'Account ID', d.account_id,
        'Status', d.status,
        'Memory', d.memory,
        'CPU', d.cpu,
        'Revision', d.revision,
        'Region', d.region
      ) as properties
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

  param "arn" {}
}

edge "aws_ecs_cluster_to_ecs_task_definition_edge" {
  title = "task defintion"

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
    ) select
      jsonb_array_elements_text(requires_compatibilities) as from_id,
      d.task_definition_arn as to_id
    from
      aws_ecs_task_definition as d
    where
      d.task_definition_arn in (
        select
          task_definition
        from
          list_all_task_definitions
      );
  EOQ

  param "arn" {}
}

node "aws_ecs_cluster_to_ecs_service_node" {
  category = category.aws_ecs_service

  sql = <<-EOQ
    select
      s.arn as id,
      s.title as title,
      jsonb_build_object(
        'ARN', s.arn,
        'launch_type', s.launch_type,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_ecs_service as s
    where
      s.cluster_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_cluster_to_ecs_service_edge" {
  title = "service"

  sql = <<-EOQ
    select
      s.task_definition as from_id,
      s.arn as to_id
    from
      aws_ecs_service as s
    where
      s.cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_cluster_to_ecs_container_instance_node" {
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
      aws_ecs_container_instance as i
      left join aws_ec2_instance as e on i.ec2_instance_id = e.instance_id
    where
      i.cluster_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_cluster_to_ecs_container_instance_edge" {
  title = "container instance"

  sql = <<-EOQ
    select
      'EC2' as from_id,
      i.arn as to_id
    from
      aws_ecs_container_instance as i
    where
      i.cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_cluster_ecs_container_instance_to_vpc_subnet_node" {
  category = category.vpc_subnet

  sql = <<-EOQ
    select
      s.subnet_arn as id,
      s.title as title,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'Subnet ID', s.subnet_id,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
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

  param "arn" {}
}

edge "aws_ecs_cluster_ecs_container_instance_to_vpc_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      i.arn as from_id,
      s.subnet_arn as to_id
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

  param "arn" {}
}

node "aws_ecs_cluster_vpc_subnet_to_vpc_node" {
  category = category.vpc_vpc

  sql = <<-EOQ
    select
      v.vpc_id as id,
      v.title as title,
      jsonb_build_object(
        'ARN', v.arn,
        'VPC ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_ecs_container_instance as i
      right join aws_ec2_instance as c on c.instance_id = i.ec2_instance_id
      right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
      right join aws_vpc as v on v.vpc_id = s.vpc_id
    where
      i.cluster_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_cluster_vpc_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      s.subnet_arn as from_id,
      v.vpc_id as to_id
    from
      aws_ecs_container_instance as i
      right join aws_ec2_instance as c  on c.instance_id = i.ec2_instance_id
      right join aws_vpc_subnet as s on s.subnet_id = c.subnet_id
      right join aws_vpc as v on v.vpc_id = s.vpc_id
    where
      i.cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_cluster_ecs_service_to_vpc_subnet_node" {
  category = category.vpc_subnet

  sql = <<-EOQ
    select
      sb.subnet_arn as id,
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
      left join
        aws_vpc_subnet as sb
        on sb.subnet_id = trim((s::text ), '""')
    where
      e.network_configuration is not null
      and e.cluster_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_cluster_ecs_service_to_vpc_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      e.arn as from_id,
      sb.subnet_arn as to_id
    from
      aws_ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join
        aws_vpc_subnet as sb
        on sb.subnet_id = trim((s::text ), '""')
    where
      e.network_configuration is not null
      and e.cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_cluster_ecs_service_subnet_to_vpc_node" {
  category = category.vpc_vpc

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
      left join
        aws_vpc_subnet as sb
        on sb.subnet_id = trim((s::text ), '""'),
      aws_vpc as v
    where
      e.network_configuration is not null
      and e.cluster_arn = $1
      and v.vpc_id = sb.vpc_id;
  EOQ

  param "arn" {}
}

edge "aws_ecs_cluster_ecs_service_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      sb.subnet_arn as from_id,
      v.arn as to_id
    from
      aws_ecs_service as e,
      jsonb_array_elements(e.network_configuration -> 'AwsvpcConfiguration' -> 'Subnets') as s
      left join aws_vpc_subnet as sb on sb.subnet_id = trim((s::text ), '""'),
      aws_vpc as v
    where
      e.network_configuration is not null
      and e.cluster_arn = $1
      and v.vpc_id = sb.vpc_id;
  EOQ

  param "arn" {}
}
