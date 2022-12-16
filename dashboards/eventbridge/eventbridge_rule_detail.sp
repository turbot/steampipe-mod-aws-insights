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
      width = 2
      args  = [self.input.eventbridge_rule_arn.value]
    }

    card {
      width = 2
      query = query.eventbridge_rule_target_count
      args  = [self.input.eventbridge_rule_arn.value]
    }
  }

  with "cloudwatch_log_groups" {
    query = query.eventbridge_rule_cloudwatch_log_groups
    args  = [self.input.eventbridge_rule_arn.value]
  }

  with "eventbridge_buses" {
    query = query.eventbridge_rule_eventbridge_buses
    args  = [self.input.eventbridge_rule_arn.value]
  }

  with "lambda_functions" {
    query = query.eventbridge_rule_lambda_functions
    args  = [self.input.eventbridge_rule_arn.value]
  }

  with "sns_topics" {
    query = query.eventbridge_rule_sns_topics
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
          cloudwatch_log_group_arns = with.cloudwatch_log_groups.rows[*].cloudwatch_log_group_arn
        }
      }

      node {
        base = node.eventbridge_bus
        args = {
          eventbridge_bus_arns = with.eventbridge_buses.rows[*].eventbridge_bus_arn
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
          lambda_function_arns = with.lambda_functions.rows[*].function_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics.rows[*].topic_arn
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

query "eventbridge_rule_cloudwatch_log_groups" {
  sql = <<-EOQ
    select
      (t ->> 'Arn')::text || ':*' as cloudwatch_log_group_arn
    from
      aws_eventbridge_rule r,
      jsonb_array_elements(targets) t
    where
      r.arn = $1
      and t ->> 'Arn' like '%logs%;
  EOQ
}

query "eventbridge_rule_eventbridge_buses" {
  sql = <<-EOQ
    select
      b.arn as eventbridge_bus_arn
    from
      aws_eventbridge_rule r
      join aws_eventbridge_bus b on b.name = r.event_bus_name
      and b.region = r.region
      and b.account_id = r.account_id
    where
      r.arn = $1;
  EOQ
}

query "eventbridge_rule_lambda_functions" {
  sql = <<-EOQ
    select
      (t ->> 'Arn')::text as function_arn
    from
      aws_eventbridge_rule r,
      jsonb_array_elements(targets) t
    where
      r.arn = $1
      and t ->> 'Arn' like '%lambda%;
  EOQ
}

query "eventbridge_rule_sns_topics" {
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
