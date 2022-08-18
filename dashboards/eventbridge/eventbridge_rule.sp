dashboard "aws_eventbridge_rule_detail" {

  title = "AWS EventBridge Rule Detail"
  # documentation = file("./dashboards/eventbridge/docs/aws_eventbridge_rule_detail.md")

  tags = merge(local.eventbridge_common_tags, {
    type = "Detail"
  })

  input "eventbridge_rule_arn" {
    title = "Select a rule:"
    query = query.aws_eventbridge_rule_input
    width = 4
  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_eventbridge_rule_relationships_graph
      args = {
        arn = self.input.eventbridge_rule_arn.value
      }

      category "aws_eventbridge_rule" {
        icon = local.aws_eventbridge_rule_icon
      }

      category "aws_eventbridge_bus" {
        icon = local.aws_eventbridge_bus_icon
      }

      category "aws_sns_topic" {
        href = "/aws_insights.dashboard.aws_sns_topic_detail.url_path?input.topic_arn={{.properties.ARN | @uri}}"
        icon = local.aws_sns_topic_icon
      }

      category "aws_lambda_function" {
        href = "/aws_insights.dashboard.aws_lambda_function_detail.url_path?input.lambda_arn={{.properties.ARN | @uri}}"
        icon = local.aws_lambda_function_icon
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

query "aws_eventbridge_rule_relationships_graph" {
  sql = <<-EOQ
    -- Eventbridge rule (node)
    select
      null as from_id,
      null as to_id,
      arn as id,
      title,
      'aws_eventbridge_rule' as category,
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
      arn = $1

    -- To EventBridge targets (node)
    -- To SNS topics (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.topic_arn as id,
      s.title,
      'aws_sns_topic' as category,
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
      and split_part((t ->> 'Arn'::text), ':', 3) = 'sns'

    -- To SNS topic (edge)
    union all
    select
      r.arn as from_id,
      s.topic_arn as to_id,
      null as id,
      'sends events' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', s.title,
        'ARN', s.topic_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_eventbridge_rule r
      cross join jsonb_array_elements(targets) t
      join aws_sns_topic s on s.topic_arn = (t ->> 'Arn')::text
    where
      r.arn = $1
      and split_part((t ->> 'Arn'::text), ':', 3) = 'sns'

    -- To Lambda functions (node)
    union all
    select
      null as from_id,
      null as to_id,
      f.arn as id,
      f.title,
      'aws_lambda_function' as category,
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
      and split_part((t ->> 'Arn'::text), ':', 3) = 'lambda'

    -- To Lambda functions (edge)
    union all
    select
      r.arn as from_id,
      f.arn as to_id,
      null as id,
      'sends events' as title,
      'uses' as category,
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
      and split_part((t ->> 'Arn'::text), ':', 3) = 'lambda'

    -- From Eventbridge bus (node)
    union all
    select
      null as from_id,
      null as to_id,
      b.arn as id,
      r.event_bus_name as title,
      'aws_eventbridge_bus' as category,
      jsonb_build_object(
        'ARN', b.arn,
        'Account ID', b.account_id,
        'Event Bus Name', r.event_bus_name
      ) as properties
    from
      aws_eventbridge_rule r
      join aws_eventbridge_bus b on b.name = r.event_bus_name
        and b.region = r.region
        and b.account_id = r.account_id
    where
      r.arn = $1

    -- From Eventbridge bus (node)
    union all
    select
      null as from_id,
      null as to_id,
      b.arn as id,
      r.event_bus_name as title,
      'aws_eventbridge_bus' as category,
      jsonb_build_object(
        'ARN', b.arn,
        'Account ID', b.account_id,
        'Event Bus Name', r.event_bus_name
      ) as properties
    from
      aws_eventbridge_rule r
      join aws_eventbridge_bus b on b.name = r.event_bus_name
        and b.region = r.region
        and b.account_id = r.account_id
    where
      r.arn = $1

    -- From Eventbridge bus (edge)
    union all
    select
      b.arn as from_id,
      r.arn as to_id,
      null as id,
      'has rule' as title,
      'uses' as category,
      jsonb_build_object(
        'Bus Name', b.name,
        'Rule Name', r.name,
        'Account ID', b.account_id,
        'Event Bus Name', r.event_bus_name
      ) as properties
    from
      aws_eventbridge_rule r
      join aws_eventbridge_bus b on b.name = r.event_bus_name
        and b.region = r.region
        and b.account_id = r.account_id
    where
      r.arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}
