dashboard "aws_ecs_task_definition_detail" {

  title         = "AWS ECS Task Definition Detail"
  documentation = file("./dashboards/ecs/docs/ecs_task_definition_detail.md")

  tags = merge(local.ecs_common_tags, {
    type = "Detail"
  })

  input "task_definition_arn" {
    title = "Select a task definition:"
    sql   = query.aws_ecs_task_definition_input.sql
    width = 4
  }

  container {

    card {
      query = query.aws_ecs_task_definition_network_mode
      width = 2
      args = {
        arn = self.input.task_definition_arn.value
      }
    }

    card {
      query = query.aws_ecs_task_definition_cpu_units
      width = 2
      args = {
        arn = self.input.task_definition_arn.value
      }
    }

    card {
      query = query.aws_ecs_task_definition_memory
      width = 2
      args = {
        arn = self.input.task_definition_arn.value
      }
    }

    card {
      query = query.aws_ecs_task_definition_requires_compatibilities
      width = 2
      args = {
        arn = self.input.task_definition_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"


      nodes = [
        node.aws_ecs_task_definition_node,
        node.aws_ecs_task_definition_from_ecs_service_node,
        node.aws_ecs_task_definition_from_ecs_task_node,
        node.aws_ecs_task_definition_to_iam_execution_role_node,
        node.aws_ecs_task_definition_to_iam_task_role_node,
        node.aws_ecs_task_definition_to_cloudwatch_log_group_node,
        node.aws_ecs_task_definition_to_efs_file_system_node,
        node.aws_ecs_task_definition_to_ecr_repository_node
      ]

      edges = [
        edge.aws_ecs_task_definition_from_ecs_service_edge,
        edge.aws_ecs_task_definition_from_ecs_task_edge,
        edge.aws_ecs_task_definition_to_iam_execution_role_edge,
        edge.aws_ecs_task_definition_to_iam_task_role_edge,
        edge.aws_ecs_task_definition_to_cloudwatch_log_group_edge,
        edge.aws_ecs_task_definition_to_efs_file_system_edge,
        edge.aws_ecs_task_definition_to_ecr_repository_edge
      ]

      args = {
        arn = self.input.task_definition_arn.value
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
        query = query.aws_ecs_task_definition_overview
        args = {
          arn = self.input.task_definition_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_ecs_task_definition_tags
        args = {
          arn = self.input.task_definition_arn.value
        }

      }
    }

    container {
      width = 6
    }

  }
}

query "aws_ecs_task_definition_input" {
  sql = <<-EOQ
    select
      title as label,
      task_definition_arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'task_definition_arn', task_definition_arn
      ) as tags
    from
      aws_ecs_task_definition
    order by
      title;
    EOQ
}

query "aws_ecs_task_definition_network_mode" {
  sql = <<-EOQ
    select
      network_mode as value,
      'Network Mode' as label
    from
      aws_ecs_task_definition
    where
      task_definition_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_task_definition_cpu_units" {
  sql = <<-EOQ
    select
      cpu as value,
      ' CPU Units' as label
    from
      aws_ecs_task_definition
    where
      task_definition_arn = $1;
  EOQ

  param "arn" {}
}


query "aws_ecs_task_definition_memory" {
  sql = <<-EOQ
    select
      memory as value,
      'Memory (MiB)' as label
    from
      aws_ecs_task_definition
    where
      task_definition_arn = $1;
  EOQ

  param "arn" {}
}


query "aws_ecs_task_definition_requires_compatibilities" {
  sql = <<-EOQ
    select
      jsonb_array_elements_text(requires_compatibilities) as value,
      'Requires Compatibilities' as label
    from
      aws_ecs_task_definition
    where
      task_definition_arn = $1;
  EOQ

  param "arn" {}
}


query "aws_ecs_task_definition_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      family as "Family",
      status as "Status",
      registered_at as "Registered At",
      registered_by as "Registered By",
      revision as "Revision",
      region as "Region",
      account_id as "Account ID",
      task_definition_arn as "ARN"
    from
      aws_ecs_task_definition
    where
      task_definition_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecs_task_definition_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ecs_task_definition,
      jsonb_array_elements(tags_src) as tag
    where
      task_definition_arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

node "aws_ecs_task_definition_node" {
  category = category.aws_ecs_task_definition

  sql = <<-EOQ
    select
      task_definition_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', task_definition_arn,
        'Status', status,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ecs_task_definition
    where
      task_definition_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_task_definition_from_ecs_service_node" {
  category = category.aws_ecs_service

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Service Name', service_name,
        'Status', status,
        'Launch Type', launch_type,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ecs_service
    where
      task_definition = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_task_definition_from_ecs_service_edge" {
  title = "service"

  sql = <<-EOQ
    select
      arn as from_id,
      $1 as to_id
    from
      aws_ecs_service
    where
      task_definition = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_task_definition_from_ecs_task_node" {
  category = category.aws_ecs_task

  sql = <<-EOQ
    select
      task_arn as id,
      concat(split_part(task_arn, '/', 2),'/' ,split_part(task_arn, '/', 3)) as title,
      jsonb_build_object(
        'ARN', task_arn,
        'cluster arn', cluster_arn,
        'Last Status', last_status,
        'Launch Type', launch_type,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ecs_task
    where
      task_definition_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_task_definition_from_ecs_task_edge" {
  title = "task"

  sql = <<-EOQ
    select
      task_arn as from_id,
      $1 as to_id
    from
      aws_ecs_task
    where
      task_definition_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_task_definition_to_iam_execution_role_node" {
  category = category.aws_iam_role

  sql = <<-EOQ
    select
      r.arn as id,
      r.name as title,
      jsonb_build_object(
        'ARN', r.arn,
        'Create Date', r.create_date,
        'Account ID', r.account_id
      ) as properties
    from
      aws_ecs_task_definition as d
      left join
        aws_iam_role as r
        on r.arn = d.execution_role_arn
        and d.task_definition_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_task_definition_to_iam_execution_role_edge" {
  title = "assumes"

  sql = <<-EOQ
    select
      d.task_definition_arn as from_id,
      d.execution_role_arn as to_id
    from
      aws_ecs_task_definition as d
      left join aws_iam_role as r on r.arn = d.execution_role_arn and d.task_definition_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_task_definition_to_iam_task_role_node" {
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
      aws_ecs_task_definition as d
      left join aws_iam_role as r on r.arn = d.task_role_arn and d.task_definition_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_task_definition_to_iam_task_role_edge" {
  title = "assumes task role"

  sql = <<-EOQ
    select
      d.task_definition_arn as from_id,
      d.task_role_arn as to_id
    from
      aws_ecs_task_definition as d
      left join aws_iam_role as r on r.arn = d.task_role_arn and d.task_definition_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_task_definition_to_cloudwatch_log_group_node" {
  category = category.aws_cloudwatch_log_group

  sql = <<-EOQ
    select
      g.arn as id,
      g.title as title,
      jsonb_build_object(
        'ARN', g.arn,
        'Creation Time', g.creation_time,
        'Retention in days', g.retention_in_days
      ) as properties
    from
      aws_ecs_task_definition as td,
      jsonb_array_elements(container_definitions) as d
      left join aws_cloudwatch_log_group as g on g.name = d -> 'LogConfiguration' -> 'Options' ->> 'awslogs-group'
    where
      d -> 'LogConfiguration' -> 'Options' ->> 'awslogs-region' = g.region
      and td.task_definition_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_task_definition_to_cloudwatch_log_group_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      task_definition_arn as from_id,
      g.arn as to_id
    from
      aws_ecs_task_definition as td,
      jsonb_array_elements(container_definitions) as d
      left join aws_cloudwatch_log_group as g on g.name = d -> 'LogConfiguration' -> 'Options' ->> 'awslogs-group'
    where
      d -> 'LogConfiguration' -> 'Options' ->> 'awslogs-region' = g.region
      and td.task_definition_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_task_definition_to_efs_file_system_node" {
  category = category.aws_efs_file_system

  sql = <<-EOQ
    select
      f.arn as id,
      f.title as title,
      jsonb_build_object(
        'ARN', f.arn,
        'Creation Time', f.creation_time,
        'Encrypted', f.encrypted,
        'Account ID', f.account_id,
        'Region', f.region
      ) as properties
    from
      aws_ecs_task_definition as td,
      jsonb_array_elements(volumes) as v
      left join aws_efs_file_system as f on f.file_system_id = v -> 'EfsVolumeConfiguration' ->> 'FileSystemId'
    where
      td.task_definition_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_task_definition_to_efs_file_system_edge" {
  title = "volume"

  sql = <<-EOQ
    select
      task_definition_arn as from_id,
      f.arn as to_id
    from
      aws_ecs_task_definition as td,
      jsonb_array_elements(volumes) as v
      left join aws_efs_file_system as f on f.file_system_id = v -> 'EfsVolumeConfiguration' ->> 'FileSystemId'
    where
      td.task_definition_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecs_task_definition_to_ecr_repository_node" {
  category = category.aws_ecr_repository

  sql = <<-EOQ
    select
      r.arn as id,
      r.title as title,
      jsonb_build_object(
        'ARN', r.arn,
        'Created At', r.created_at,
        'Repository URI', r.repository_uri,
        'Account ID', r.account_id,
        'Region', r.region
      ) as properties
    from
      aws_ecs_task_definition as td,
      jsonb_array_elements(container_definitions) as d
      left join aws_ecr_repository as r on r.repository_uri = split_part(d ->> 'Image', ':', 1)
    where
      td.task_definition_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecs_task_definition_to_ecr_repository_edge" {
  title = "ecr repository"

  sql = <<-EOQ
    select
      task_definition_arn as from_id,
      r.arn as to_id
    from
      aws_ecs_task_definition as td,
      jsonb_array_elements(container_definitions) as d
      left join aws_ecr_repository as r on r.repository_uri = split_part(d ->> 'Image', ':', 1)
    where
      td.task_definition_arn = $1;
  EOQ

  param "arn" {}
}
