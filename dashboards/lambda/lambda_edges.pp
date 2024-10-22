edge "lambda_function_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      f.arn as from_id,
      g.arn as to_id
    from
      aws_cloudwatch_log_group as g
      left join aws_lambda_function as f on f.name = split_part(g.name, '/', 4)
      join unnest($1::text[]) as a on f.arn = a and f.account_id = split_part(a, ':', 5) and f.region = split_part(a, ':', 4)
    where
      g.name like '/aws/lambda/%'
      and g.region = f.region
      and f.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      l.arn as from_id,
      l.role as to_id
    from
      aws_lambda_function as l
      join unnest($1::text[]) as a on l.arn = a and l.account_id = split_part(a, ':', 5) and l.region = split_part(a, ':', 4)
    where
      l.role is not null;
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      l.arn as from_id,
      l.kms_key_arn as to_id
    from
      aws_lambda_function as l
      join unnest($1::text[]) as a on l.arn = a and l.account_id = split_part(a, ':', 5) and l.region = split_part(a, ':', 4)
    where
      l.kms_key_arn is not null;
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_lambda_alias" {
  title = "alias"

  sql = <<-EOQ
    with lambda_alias as (
      select
        alias_arn,
        function_name,
        function_version,
        account_id,
        region
      from
        aws_lambda_alias
    ), lambda_function as (
      select
        name,
        arn,
        account_id,
        region
      from
        aws_lambda_function
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      concat(l.arn, ':', a.function_version) as from_id,
      a.alias_arn as to_id
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

edge "lambda_function_to_lambda_version" {
  title = "version"

  sql = <<-EOQ
    with lambda_version as (
      select
        function_name,
        arn,
        account_id,
        region
      from
        aws_lambda_version
    ), lambda_function as (
      select
        name,
        arn,
        account_id,
        region
      from
        aws_lambda_function
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      l.arn as from_id,
      v.arn as to_id
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

edge "lambda_function_to_sqs_queue" {
  title = "queues"

  sql = <<-EOQ
    select
      arn as from_id,
      dead_letter_config_target_arn as to_id
    from
      aws_lambda_function
    where
      dead_letter_config_target_arn = any($1);
  EOQ

  param "sqs_queue_arns" {}
}

edge "lambda_function_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      l.arn as from_id,
      s as to_id
    from
      aws_lambda_function as l
      join unnest($1::text[]) as a on l.arn = a and l.account_id = split_part(a, ':', 5) and l.region = split_part(a, ':', 4),
      jsonb_array_elements_text(vpc_security_group_ids) as s;
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      sg as from_id,
      s as to_id
    from
      aws_lambda_function as l
      join unnest($1::text[]) as a on l.arn = a and l.account_id = split_part(a, ':', 5) and l.region = split_part(a, ':', 4),
      jsonb_array_elements_text(vpc_subnet_ids) as s,
      jsonb_array_elements_text(vpc_security_group_ids) as sg;
  EOQ

  param "lambda_function_arns" {}
}

