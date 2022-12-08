edge "lambda_function_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      f.arn as from_id,
      g.arn as to_id
    from
      aws_cloudwatch_log_group as g
      left join aws_lambda_function as f on f.name = split_part(g.name, '/', 4)
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
    where
      l.role is not null
      and l.arn = any($1);
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
    where
      l.kms_key_arn is not null
      and l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_lambda_alias" {
  title = "alias"

  sql = <<-EOQ
    select
      concat(l.arn, ':', a.function_version) as from_id,
      a.alias_arn as to_id
    from
      aws_lambda_function as l,
      aws_lambda_alias as a
    where
      a.function_name = l.name
      and a.account_id = l.account_id
      and a.region = l.region
      and l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_lambda_version" {
  title = "version"

  sql = <<-EOQ
    select
      l.arn as from_id,
      v.arn as to_id
    from
      aws_lambda_function as l,
      aws_lambda_version as v
    where
      l.name = v.function_name
      and l.account_id = v.account_id
      and l.region = v.region
      and l.arn = any($1);
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
      aws_lambda_function as l,
      jsonb_array_elements_text(vpc_security_group_ids) as s
    where
      l.arn = any($1);
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
      aws_lambda_function as l,
      jsonb_array_elements_text(vpc_subnet_ids) as s,
      jsonb_array_elements_text(vpc_security_group_ids) as sg
    where
      l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

