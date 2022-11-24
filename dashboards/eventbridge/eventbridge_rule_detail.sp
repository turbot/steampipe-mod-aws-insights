dashboard "aws_eventbridge_rule_detail" {

  title         = "AWS EventBridge Rule Detail"
  documentation = file("./dashboards/eventbridge/docs/aws_eventbridge_rule_detail.md")

  tags = merge(local.eventbridge_common_tags, {
    type = "Detail"
  })

  input "eventbridge_rule_arn" {
    title = "Select a rule:"
    query = query.aws_eventbridge_rule_input
    width = 4
  }

  container {
    card {
      query = query.aws_eventbridge_rule_state
      width = 2
      args = {
        arn = self.input.eventbridge_rule_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_eventbridge_rule_target_count
      args = {
        arn = self.input.eventbridge_rule_arn.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_eventbridge_rule_node,
        node.aws_eventbridge_rule_to_sns_topic_node,
        node.aws_eventbridge_rule_to_lambda_function_node,
        node.aws_eventbridge_rule_to_cloudwatch_log_group_node,
        node.aws_eventbridge_rule_to_eventbridge_bus_node
      ]

      edges = [
        edge.aws_eventbridge_rule_to_sns_topic_edge,
        edge.aws_eventbridge_rule_to_lambda_function_edge,
        edge.aws_eventbridge_rule_to_cloudwatch_log_group_edge,
        edge.aws_eventbridge_rule_to_eventbridge_bus_edge
      ]

      args = {
        arn = self.input.eventbridge_rule_arn.value
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
        query = query.aws_eventbridge_rule_overview
        args = {
          arn = self.input.eventbridge_rule_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_eventbridge_rule_tags
        args = {
          arn = self.input.eventbridge_rule_arn.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Targets"
        query = query.aws_eventbridge_rule_targets
        args = {
          arn = self.input.eventbridge_rule_arn.value
        }
      }
    }
  }
}


query "aws_eventbridge_rule_input" {
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

query "aws_eventbridge_rule_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(state) as value
    from
      aws_eventbridge_rule
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_eventbridge_rule_overview" {
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

  param "arn" {}
}

query "aws_eventbridge_rule_tags" {
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

  param "arn" {}
}

query "aws_eventbridge_rule_targets" {
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

  param "arn" {}
}

query "aws_eventbridge_rule_target_count" {
  sql = <<-EOQ
    select
      coalesce(jsonb_array_length(targets), 0) as value,
      'Targets' as label
    from
      aws_eventbridge_rule
    where
      arn = $1
  EOQ

  param "arn" {}
}

node "aws_eventbridge_rule_node" {
  category = category.aws_eventbridge_rule

  sql = <<-EOQ
     select
      arn as id,
      title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Event Bus Name', event_bus_name,
        'Managed by', managed_by,
        'Region', region,
        'State', state
      ) as properties
    from
      aws_eventbridge_rule
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_eventbridge_rule_to_sns_topic_node" {
  category = category.aws_sns_topic

  sql = <<-EOQ
     select
      s.topic_arn as id,
      s.title,
      jsonb_build_object(
        'ARN', s.topic_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_eventbridge_rule r
      cross join jsonb_array_elements(targets) t
      join aws_sns_topic s on s.topic_arn = (t ->> 'Arn')::text
    where
      arn = $1
      and split_part((t ->> 'Arn'::text), ':', 3) = 'sns';
  EOQ

  param "arn" {}
}

edge "aws_eventbridge_rule_to_sns_topic_edge" {
  title = "notifies"

  sql = <<-EOQ
     select
      r.arn as from_id,
      s.topic_arn as to_id
    from
      aws_eventbridge_rule r
      cross join jsonb_array_elements(targets) t
      join aws_sns_topic s on s.topic_arn = (t ->> 'Arn')::text
    where
      r.arn = $1
      and split_part((t ->> 'Arn'::text), ':', 3) = 'sns';
  EOQ

  param "arn" {}
}

node "aws_eventbridge_rule_to_lambda_function_node" {
  category = category.aws_lambda_function

  sql = <<-EOQ
     select
      f.arn as id,
      f.title,
      jsonb_build_object(
        'ARN', f.arn,
        'Account ID', f.account_id,
        'Region', f.region
      ) as properties
    from
      aws_eventbridge_rule r
      cross join jsonb_array_elements(targets) t
      join aws_lambda_function f on f.arn = (t ->> 'Arn')::text
    where
      r.arn = $1
      and split_part((t ->> 'Arn'::text), ':', 3) = 'lambda';
  EOQ

  param "arn" {}
}

edge "aws_eventbridge_rule_to_lambda_function_edge" {
  title = "triggers"

  sql = <<-EOQ
     select
      r.arn as from_id,
      f.arn as to_id
    from
      aws_eventbridge_rule r
      cross join jsonb_array_elements(targets) t
      join aws_lambda_function f on f.arn = (t ->> 'Arn')::text
    where
      r.arn = $1
      and split_part((t ->> 'Arn'::text), ':', 3) = 'lambda';
  EOQ

  param "arn" {}
}

node "aws_eventbridge_rule_to_cloudwatch_log_group_node" {
  category = category.aws_cloudwatch_log_group

  sql = <<-EOQ
     select
      w.arn as id,
      w.title,
      jsonb_build_object(
        'ARN', w.arn,
        'Account ID', w.account_id,
        'Region', w.region,
        'Retention days', w.retention_in_days
      ) as properties
    from
      aws_eventbridge_rule r
      cross join jsonb_array_elements(targets) t
      join aws_cloudwatch_log_group w on w.arn = (t ->> 'Arn')::text || ':*'
    where
      r.arn = $1
      and split_part((t ->> 'Arn'::text), ':', 3) = 'logs';
  EOQ

  param "arn" {}
}

edge "aws_eventbridge_rule_to_cloudwatch_log_group_edge" {
  title = "logs to"

  sql = <<-EOQ
     select
      r.arn as from_id,
      w.arn as to_id
    from
      aws_eventbridge_rule r
      cross join jsonb_array_elements(targets) t
      join aws_cloudwatch_log_group w on w.arn = (t ->> 'Arn')::text || ':*'
    where
      r.arn = $1
      and split_part((t ->> 'Arn'::text), ':', 3) = 'logs';
  EOQ

  param "arn" {}
}

node "aws_eventbridge_rule_to_eventbridge_bus_node" {
  category = category.aws_eventbridge_bus

  sql = <<-EOQ
     select
      null as from_id,
      null as to_id,
      b.arn as id,
      r.event_bus_name as title,
      'aws_eventbridge_bus' as category,
      jsonb_build_object(
        'ARN', b.arn,
        'Account ID', b.account_id,
        'Event Bus Name', r.event_bus_name,
        'Region', r.region
      ) as properties
    from
      aws_eventbridge_rule r
      join aws_eventbridge_bus b on b.name = r.event_bus_name
        and b.region = r.region
        and b.account_id = r.account_id
    where
      r.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_eventbridge_rule_to_eventbridge_bus_edge" {
  title = "eventbridge rule"

  sql = <<-EOQ
     select
      b.arn as from_id,
      r.arn as to_id
    from
      aws_eventbridge_rule r
      join aws_eventbridge_bus b on b.name = r.event_bus_name
        and b.region = r.region
        and b.account_id = r.account_id
    where
      r.arn = $1;
  EOQ

  param "arn" {}
}
