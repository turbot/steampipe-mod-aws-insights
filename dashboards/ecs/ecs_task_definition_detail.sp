dashboard "ecs_task_definition_detail" {

  title         = "AWS ECS Task Definition Detail"
  documentation = file("./dashboards/ecs/docs/ecs_task_definition_detail.md")

  tags = merge(local.ecs_common_tags, {
    type = "Detail"
  })

  input "task_definition_arn" {
    title = "Select a task definition:"
    query = query.ecs_task_definition_input
    width = 4
  }

  container {

    card {
      query = query.ecs_task_definition_network_mode
      width = 3
      args  = [self.input.task_definition_arn.value]
    }

    card {
      query = query.ecs_task_definition_cpu_units
      width = 3
      args  = [self.input.task_definition_arn.value]
    }

    card {
      query = query.ecs_task_definition_memory
      width = 3
      args  = [self.input.task_definition_arn.value]
    }

    card {
      query = query.ecs_task_definition_requires_compatibilities
      width = 3
      args  = [self.input.task_definition_arn.value]
    }

  }

  with "cloudwatch_log_groups_for_ecs_task_definition" {
    query = query.cloudwatch_log_groups_for_ecs_task_definition
    args  = [self.input.task_definition_arn.value]
  }

  with "ecr_repositories_for_ecs_task_definition" {
    query = query.ecr_repositories_for_ecs_task_definition
    args  = [self.input.task_definition_arn.value]
  }

  with "ecs_services_for_ecs_task_definition" {
    query = query.ecs_services_for_ecs_task_definition
    args  = [self.input.task_definition_arn.value]
  }

  with "ecs_tasks_for_ecs_task_definition" {
    query = query.ecs_tasks_for_ecs_task_definition
    args  = [self.input.task_definition_arn.value]
  }

  with "efs_file_systems_for_ecs_task_definition" {
    query = query.efs_file_systems_for_ecs_task_definition
    args  = [self.input.task_definition_arn.value]
  }

  with "iam_roles_for_ecs_task_definition" {
    query = query.iam_roles_for_ecs_task_definition
    args  = [self.input.task_definition_arn.value]
  }


  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.cloudwatch_log_group
        args = {
          cloudwatch_log_group_arns = with.cloudwatch_log_groups_for_ecs_task_definition.rows[*].log_group_arn
        }
      }

      node {
        base = node.ecr_repository
        args = {
          ecr_repository_arns = with.ecr_repositories_for_ecs_task_definition.rows[*].repository_arn
        }
      }

      node {
        base = node.ecs_service
        args = {
          ecs_service_arns = with.ecs_services_for_ecs_task_definition.rows[*].service_arn
        }
      }

      node {
        base = node.ecs_task
        args = {
          ecs_task_arns = with.ecs_tasks_for_ecs_task_definition.rows[*].task_arn
        }
      }

      node {
        base = node.ecs_task_definition
        args = {
          ecs_task_definition_arns = [self.input.task_definition_arn.value]
        }
      }

      node {
        base = node.efs_file_system
        args = {
          efs_file_system_arns = with.efs_file_systems_for_ecs_task_definition.rows[*].file_system_arn
        }
      }

      node {
        base = node.iam_role
        args = {
          iam_role_arns = with.iam_roles_for_ecs_task_definition.rows[*].role_arn
        }
      }

      edge {
        base = edge.ecs_service_to_ecs_task
        args = {
          ecs_service_arns = with.ecs_services_for_ecs_task_definition.rows[*].service_arn
        }
      }

      edge {
        base = edge.ecs_service_to_ecs_task_definition
        args = {
          ecs_service_arns = with.ecs_services_for_ecs_task_definition.rows[*].service_arn
        }
      }

      edge {
        base = edge.ecs_task_definition_to_cloudwatch_log_group
        args = {
          ecs_task_definition_arns = [self.input.task_definition_arn.value]
        }
      }

      edge {
        base = edge.ecs_task_definition_to_ecr_repository
        args = {
          ecs_task_definition_arns = [self.input.task_definition_arn.value]
        }
      }

      edge {
        base = edge.ecs_task_definition_to_efs_file_system
        args = {
          ecs_task_definition_arns = [self.input.task_definition_arn.value]
        }
      }

      edge {
        base = edge.ecs_task_definition_to_iam_execution_role
        args = {
          ecs_task_definition_arns = [self.input.task_definition_arn.value]
        }
      }

      edge {
        base = edge.ecs_task_definition_to_iam_task_role
        args = {
          ecs_task_definition_arns = [self.input.task_definition_arn.value]
        }
      }

      edge {
        base = edge.ecs_task_to_ecs_task_definition
        args = {
          ecs_task_arns = with.ecs_tasks_for_ecs_task_definition.rows[*].task_arn
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
        query = query.ecs_task_definition_overview
        args  = [self.input.task_definition_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.ecs_task_definition_tags
        args  = [self.input.task_definition_arn.value]

      }
    }

  }
}

# Input queries

query "ecs_task_definition_input" {
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

# With queries

query "cloudwatch_log_groups_for_ecs_task_definition" {
  sql = <<-EOQ
    select
      g.arn as log_group_arn
    from
      aws_ecs_task_definition as td,
      jsonb_array_elements(container_definitions) as d
      left join aws_cloudwatch_log_group as g on g.name = d -> 'LogConfiguration' -> 'Options' ->> 'awslogs-group'
    where
      d -> 'LogConfiguration' -> 'Options' ->> 'awslogs-region' = g.region
      and td.task_definition_arn = $1
      and td.account_id = split_part($1, ':', 5)
      and td.region = split_part($1, ':', 4);
  EOQ
}

query "ecr_repositories_for_ecs_task_definition" {
  sql = <<-EOQ
    select
      r.arn as repository_arn
    from
      aws_ecs_task_definition as td,
      jsonb_array_elements(container_definitions) as d
      left join aws_ecr_repository as r on r.repository_uri = split_part(d ->> 'Image', ':', 1)
    where
      r.arn is not null
      and td.task_definition_arn = $1
      and td.account_id = split_part($1, ':', 5)
      and td.region = split_part($1, ':', 4);
  EOQ
}

query "ecs_services_for_ecs_task_definition" {
  sql = <<-EOQ
    select
      arn as service_arn
    from
      aws_ecs_service
    where
      task_definition = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "ecs_tasks_for_ecs_task_definition" {
  sql = <<-EOQ
    select
      task_arn as task_arn
    from
      aws_ecs_task
    where
      task_definition_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "efs_file_systems_for_ecs_task_definition" {
  sql = <<-EOQ
    select
      f.arn as file_system_arn
    from
      aws_ecs_task_definition as td,
      jsonb_array_elements(volumes) as v
      left join aws_efs_file_system as f on f.file_system_id = v -> 'EfsVolumeConfiguration' ->> 'FileSystemId'
    where
      td.task_definition_arn = $1
      and td.account_id = split_part($1, ':', 5)
      and td.region = split_part($1, ':', 4);
  EOQ
}

query "iam_roles_for_ecs_task_definition" {
  sql = <<-EOQ
    select
      r.arn as role_arn
    from
      aws_ecs_task_definition as d
      left join
        aws_iam_role as r
        on r.arn = d.execution_role_arn
        and d.task_definition_arn = $1
    where
      r.arn is not null
    union
    select
      r.arn as role_arn
    from
      aws_ecs_task_definition as d
      left join aws_iam_role as r on r.arn = d.task_role_arn and d.task_definition_arn = $1
    where
      r.arn is not null
  EOQ
}

# Card queries

query "ecs_task_definition_network_mode" {
  sql = <<-EOQ
    select
      network_mode as value,
      'Network Mode' as label
    from
      aws_ecs_task_definition
    where
      task_definition_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "ecs_task_definition_cpu_units" {
  sql = <<-EOQ
    select
      cpu as value,
      ' CPU Units' as label
    from
      aws_ecs_task_definition
    where
      task_definition_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "ecs_task_definition_memory" {
  sql = <<-EOQ
    select
      memory as value,
      'Memory (MiB)' as label
    from
      aws_ecs_task_definition
    where
      task_definition_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "ecs_task_definition_requires_compatibilities" {
  sql = <<-EOQ
    select
      jsonb_array_elements_text(requires_compatibilities) as value,
      'Requires Compatibilities' as label
    from
      aws_ecs_task_definition
    where
      task_definition_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

# Other detail page queries

query "ecs_task_definition_overview" {
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
      task_definition_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "ecs_task_definition_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ecs_task_definition,
      jsonb_array_elements(tags_src) as tag
    where
      task_definition_arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
    order by
      tag ->> 'Key';
  EOQ
}
