dashboard "eventbridge_rule_detail" {

  title         = "AWS EventBridge Rule Detail"
  documentation = file("./dashboards/eventbridge/docs/eventbridge_rule_detail.md")

  tags = merge(local.eventbridge_common_tags, {
    type = "Detail"
  })

  input "eventbridge_rule_arn" {
    title = "Select a rule:"
    query = query.eventbridge_rule_input
    width = 4
  }

  container {
    card {
      query = query.eventbridge_rule_state
      width = 3
      args  = [self.input.eventbridge_rule_arn.value]
    }

    card {
      width = 3
      query = query.eventbridge_rule_target_count
      args  = [self.input.eventbridge_rule_arn.value]
    }
  }

  with "cloudwatch_log_groups_for_eventbridge_rule" {
    query = query.cloudwatch_log_groups_for_eventbridge_rule
    args  = [self.input.eventbridge_rule_arn.value]
  }

  with "eventbridge_buses_for_eventbridge_rule" {
    query = query.eventbridge_buses_for_eventbridge_rule
    args  = [self.input.eventbridge_rule_arn.value]
  }

  with "lambda_functions_for_eventbridge_rule" {
    query = query.lambda_functions_for_eventbridge_rule
    args  = [self.input.eventbridge_rule_arn.value]
  }

  with "sns_topics_for_eventbridge_rule" {
    query = query.sns_topics_for_eventbridge_rule
    args  = [self.input.eventbridge_rule_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.cloudwatch_log_group
        args = {
          cloudwatch_log_group_arns = with.cloudwatch_log_groups_for_eventbridge_rule.rows[*].cloudwatch_log_group_arn
        }
      }

      node {
        base = node.eventbridge_bus
        args = {
          eventbridge_bus_arns = with.eventbridge_buses_for_eventbridge_rule.rows[*].eventbridge_bus_arn
        }
      }

      node {
        base = node.eventbridge_rule
        args = {
          eventbridge_rule_arns = [self.input.eventbridge_rule_arn.value]
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = with.lambda_functions_for_eventbridge_rule.rows[*].function_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics_for_eventbridge_rule.rows[*].topic_arn
        }
      }

      edge {
        base = edge.eventbridge_rule_to_cloudwatch_log_group
        args = {
          eventbridge_rule_arns = [self.input.eventbridge_rule_arn.value]
        }
      }

      edge {
        base = edge.eventbridge_rule_to_eventbridge_bus
        args = {
          eventbridge_rule_arns = [self.input.eventbridge_rule_arn.value]
        }
      }

      edge {
        base = edge.eventbridge_rule_to_lambda_function
        args = {
          eventbridge_rule_arns = [self.input.eventbridge_rule_arn.value]
        }
      }

      edge {
        base = edge.eventbridge_rule_to_sns_topic
        args = {
          eventbridge_rule_arns = [self.input.eventbridge_rule_arn.value]
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
        query = query.eventbridge_rule_overview
        args  = [self.input.eventbridge_rule_arn.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.eventbridge_rule_tags
        args  = [self.input.eventbridge_rule_arn.value]
      }

    }

    container {
      width = 6

      table {
        title = "Targets"
        query = query.eventbridge_rule_targets
        args  = [self.input.eventbridge_rule_arn.value]
      }
    }
  }
}

# Input queries

query "eventbridge_rule_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_eventbridge_rule
    order by
      arn;
  EOQ
}

# With queries

query "cloudwatch_log_groups_for_eventbridge_rule" {
  sql = <<-EOQ
    select
      (t ->> 'Arn')::text || ':*' as cloudwatch_log_group_arn
    from
      aws_eventbridge_rule r,
      jsonb_array_elements(targets) t
    where
      r.arn = $1
      and t ->> 'Arn' like '%logs%';
  EOQ
}

query "eventbridge_buses_for_eventbridge_rule" {
  sql = <<-EOQ
    select
      b.arn as eventbridge_bus_arn
    from
      aws_eventbridge_rule r
      join aws_eventbridge_bus b on b.name = r.event_bus_name
    where
      r.arn = $1
      and b.region = split_part($1, ':', 4)
      and b.account_id = split_part($1, ':', 5)
  EOQ
}

query "lambda_functions_for_eventbridge_rule" {
  sql = <<-EOQ
    select
      (t ->> 'Arn')::text as function_arn
    from
      aws_eventbridge_rule r,
      jsonb_array_elements(targets) t
    where
      r.arn = $1
      and t ->> 'Arn' like '%lambda%';
  EOQ
}

query "sns_topics_for_eventbridge_rule" {
  sql = <<-EOQ
    select
      (t ->> 'Arn')::text as topic_arn
    from
      aws_eventbridge_rule r,
      jsonb_array_elements(targets) t
    where
      arn = $1
      and t ->> 'Arn' like '%sns%';
  EOQ
}

# Card queries

query "eventbridge_rule_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(state) as value
    from
      aws_eventbridge_rule
    where
      arn = $1;
  EOQ
}

query "eventbridge_rule_target_count" {
  sql = <<-EOQ
    select
      coalesce(jsonb_array_length(targets), 0) as value,
      'Targets' as label
    from
      aws_eventbridge_rule
    where
      arn = $1
  EOQ
}

# Other detail page queries

query "eventbridge_rule_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      event_bus_name as "Event Bus Name",
      managed_by as "Managed by",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_eventbridge_rule
    where
      arn = $1;
  EOQ
}

query "eventbridge_rule_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_eventbridge_rule,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ
}

query "eventbridge_rule_targets" {
  sql = <<-EOQ
    select
      target ->> 'Id' as "ID",
      target ->> 'Arn' as "ARN",
      target ->> 'Input' as "Input"
    from
      aws_eventbridge_rule as c,
      jsonb_array_elements(c.targets) as target
    where
      c.arn = $1;
  EOQ
}
