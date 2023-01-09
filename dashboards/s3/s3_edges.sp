edge "s3_bucket_to_codebuild_project" {
  title = "source provider"

  sql = <<-EOQ
    select
      s3.arn as from_id,
      p.arn as to_id
    from
      aws_codebuild_project as p,
      aws_s3_bucket as s3
    where
      p.arn = any($1)
      and s3.name = split_part(p.source ->> 'Location', '/', 1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "s3_bucket_to_cloudfront_distribution" {
  title = "origin for"

  sql = <<-EOQ
    select
      b.arn as from_id,
      d.arn as to_id
    from
      aws_cloudfront_distribution as d,
      jsonb_array_elements(origins) as origin
      left join aws_s3_bucket as b on origin ->> 'DomainName' like '%' || b.name || '%'
    where
      d.arn = any($1);
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
