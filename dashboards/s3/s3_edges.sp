edge "s3_bucket_to_codebuild_project" {
  title = "source provider"

  sql = <<-EOQ
    with s3_bucket as (
      select
        name,
        arn
      from
        aws_s3_bucket
    )
    select
      s3.arn as from_id,
      p.arn as to_id
    from
      aws_codebuild_project as p
      join unnest($1::text[]) as a on p.arn = a and p.account_id = split_part(a, ':', 5) and p.region = split_part(a, ':', 4),
      s3_bucket as s3
    where
      s3.name = split_part(p.source ->> 'Location', '/', 1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "s3_bucket_to_cloudfront_distribution" {
  title = "origin for"

  sql = <<-EOQ
    with s3_bucket as (
      select
        name,
        arn
      from
        aws_s3_bucket
    )
    select
      b.arn as from_id,
      d.arn as to_id
    from
      aws_cloudfront_distribution as d
      join unnest($1::text[]) as a on d.arn = a and d.account_id = split_part(a, ':', 5) and d.region = split_part(a, ':', 4),
      jsonb_array_elements(origins) as origin
      left join s3_bucket as b on origin ->> 'DomainName' like '%' || b.name || '%';
  EOQ

  param "cloudfront_distribution_arns" {}
}

edge "s3_bucket_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      b.arn as from_id,
      r -> 'ApplyServerSideEncryptionByDefault' ->> 'KMSMasterKeyID' as to_id
    from
      aws_s3_bucket as b
      cross join jsonb_array_elements(server_side_encryption_configuration -> 'Rules') as r
    where
      arn = any($1);
  EOQ

  param "s3_bucket_arns" {}
}

edge "s3_bucket_to_lambda_function" {
  title = "triggers"

  sql = <<-EOQ
    select
      b.arn as from_id,
      t ->> 'LambdaFunctionArn' as to_id
    from
      aws_s3_bucket as b,
      jsonb_array_elements(event_notification_configuration -> 'LambdaFunctionConfigurations') as t
    where
      event_notification_configuration ->> 'LambdaFunctionConfigurations' is not null
      and arn = any($1);
  EOQ

  param "s3_bucket_arns" {}
}

edge "s3_bucket_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    select
      b.arn as from_id,
      lb.arn as to_id
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = any($1)
      and lb.name = b.logging ->> 'TargetBucket';
  EOQ

  param "s3_bucket_arns" {}
}

edge "s3_bucket_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      b.arn as from_id,
      t ->> 'TopicArn' as to_id
    from
      aws_s3_bucket as b,
      jsonb_array_elements(event_notification_configuration -> 'TopicConfigurations') as t
    where
      event_notification_configuration ->> 'TopicConfigurations' is not null
      and arn = any($1);
  EOQ

  param "s3_bucket_arns" {}
}

edge "s3_bucket_to_sqs_queue" {
  title = "queues"

  sql = <<-EOQ
    select
      b.arn as from_id,
      q ->> 'QueueArn' as to_id
    from
      aws_s3_bucket as b,
      jsonb_array_elements(event_notification_configuration -> 'QueueConfigurations') as q
    where
      event_notification_configuration ->> 'QueueConfigurations' is not null
      and arn = any($1);
  EOQ

  param "s3_bucket_arns" {}
}
