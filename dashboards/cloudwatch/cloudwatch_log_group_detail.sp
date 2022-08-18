dashboard "aws_cloudwatch_log_group_detail" {

  title         = "AWS CloudWatch Log Group Detail"
  documentation = file("./dashboards/cloudwatch/docs/cloudwatch_log_group_detail.md")

  tags = merge(local.cloudwatch_common_tags, {
    type = "Detail"
  })

  input "log_group_arn" {
    title = "Select a log group:"
    sql   = query.aws_cloudwatch_log_group_input.sql
    width = 4
  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_cloudwatch_log_group_relationships_graph
      args  = {
        log_group_arn = self.input.log_group_arn.value
      }

      category "aws_cloudwatch_log_group" {
        icon = local.aws_cloudwatch_log_group_icon
      }

      category "aws_kms_key" {
        href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
        icon = local.aws_kms_key_icon
      }

      category "aws_cloudtrail_trail" {
        icon = local.aws_cloudtrail_trail_icon
      }

      category "aws_lambda_function" {
        icon = local.aws_lambda_function_icon
        color = "blue"
        href  = "${dashboard.aws_lambda_function_detail.url_path}?input.lambda_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_vpc_flow_log" {
        icon = local.aws_vpc_flow_log_icon
        href  = "${dashboard.aws_vpc_flow_log_detail.url_path}?input.flow_log_id={{.properties.'ID' | @uri}}"
      }
    }
  }

}

query "aws_cloudwatch_log_group_input" {
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
      aws_cloudwatch_log_group
    order by
      title;
  EOQ
}

query "aws_cloudwatch_log_group_relationships_graph" {
  sql = <<-EOQ
  with log_group as (select * from aws_cloudwatch_log_group where arn = $1)

    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_cloudwatch_log_group' as category,
      jsonb_build_object(
        'Creation Time', creation_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      log_group

    -- To Kms keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      k.arn as id,
      k.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'ID', k.id,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      log_group as g
      left join aws_kms_key as k on k.arn = g.kms_key_id
    where
      k.region = g.region

    -- To Kms keys (edge)
    union all
    select
      g.arn as from_id,
      k.arn as to_id,
      null as id,
      'encrypts with' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'ID', k.id,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      log_group as g
      left join aws_kms_key as k on k.arn = g.kms_key_id
    where
      k.region = g.region

    -- From Cloudtrail Trails (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_cloudtrail_trail' as category,
      jsonb_build_object(
        'ARN', t.arn,
        'Is Logging', t.is_logging,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_cloudtrail_trail as t
    where
      t.log_group_arn  = (select arn from log_group )

    -- From Cloudtrail Trails (edge)
    union all
    select
      c.arn as from_id,
      $1 as to_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Is Logging', c.is_logging,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      log_group as g
      left join aws_cloudtrail_trail as c on g.arn = c.log_group_arn

    -- From Lambda Function (node)
    union all
      select
      null as from_id,
      null as to_id,
      f.arn as id,
      f.title as title,
      'aws_lambda_function' as category,
      jsonb_build_object(
        'ARN', f.arn,
        'Account ID', f.account_id,
        'Region', f.region
      ) as properties
    from
      log_group as g
      left join aws_lambda_function as f on f.name = split_part(g.name, '/', 4)
    where
      g.name like '/aws/lambda/%'
      and g.region = f.region

    -- From Lambda Function  (edge)
    union all
    select
      f.arn as from_id,
      $1 as to_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', f.arn,
        'Account ID', f.account_id,
        'Region', f.region
      ) as properties
    from
      log_group as g
      left join aws_lambda_function as f on f.name = split_part(g.name, '/', 4)
    where
      g.name like '/aws/lambda/%'
      and g.region = f.region

    -- From VPC Flow Log (node)
    union all
    select
      null as from_id,
      null as to_id,
      f.flow_log_id as id,
      f.title as title,
      'aws_vpc_flow_log' as category,
      jsonb_build_object(
        'ID', f.flow_log_id ,
        'Traffic Type', f.traffic_type,
        'Resource ID', f.resource_id,
        'Region', f.region,
        'Account ID', f.account_id
      ) as properties
    from
      log_group as g
      left join aws_vpc_flow_log as f on g.name = f.log_group_name
    where
      f.region = g.region

    -- From VPC Flow Log (edge)
    union all
    select
      f.flow_log_id as from_id,
      $1 as to_id,
      null as id,
      'logs to' as title,
      'logs to' as category,
      jsonb_build_object(
        'ID', f.flow_log_id ,
        'Region', f.region,
        'Account ID', f.account_id
      ) as properties
    from
      log_group as g
      left join aws_vpc_flow_log as f on g.name = f.log_group_name
    where
      f.region = g.region
  EOQ
  param "log_group_arn" {}

}
