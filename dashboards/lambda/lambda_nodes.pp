
node "lambda_alias" {
  category = category.lambda_alias

  sql = <<-EOQ
    with lambda_alias as (
      select
        function_name,
        alias_arn,
        title,
        name,
        description,
        region,
        account_id
      from
        aws_lambda_alias
    ), lambda_function as (
      select
        name,
        arn,
        region,
        account_id
      from
        aws_lambda_function
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      a.alias_arn as id,
      a.title as title,
      jsonb_build_object(
        'Name', a.name,
        'Description', a.description,
        'ARN', a.alias_arn,
        'Region', a.region,
        'Account ID', a.account_id
      ) as properties
    from
      lambda_function as l,
      lambda_alias as a
    where
      a.function_name = l.name
      and a.account_id = l.account_id
      and a.region = l.region;
  EOQ

  param "lambda_function_arns" {}
}

node "lambda_function" {
  category = category.lambda_function

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Runtime', runtime,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_lambda_function
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "lambda_function_arns" {}
}

node "lambda_function_sns_topic_subscription" {
  category = category.sns_topic_subscription

  sql = <<-EOQ
    select
      subscription_arn as id,
      split_part(title, '-', 1) as title,
      jsonb_build_object(
        'ARN', subscription_arn,
        'Endpoint', endpoint,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_sns_topic_subscription
    where
      protocol = 'lambda'
      and (
        endpoint = $1
        or endpoint like $1 || ':%'
      )

  EOQ

  param "lambda_function_arn" {}
}

node "lambda_version" {
  category = category.lambda_version

  sql = <<-EOQ
    with lambda_version as (
      select
        arn,
        function_name,
        title,
        version,
        runtime,
        description,
        region,
        account_id
      from
        aws_lambda_version
    ), lambda_function as (
      select
        name,
        arn,
        region,
        account_id
      from
        aws_lambda_function
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      v.arn as id,
      v.title as title,
      jsonb_build_object(
        'Version', v.version,
        'ARN', v.arn,
        'Runtime', v.runtime,
        'Region', v.region,
        'Account ID', v.account_id
      ) as properties
    from
      lambda_function as l,
      lambda_version as v
    where
      l.name = v.function_name
      and l.account_id = v.account_id
      and l.region = v.region;
  EOQ

  param "lambda_function_arns" {}
}
