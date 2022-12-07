node "kms_key" {
  category = category.kms_key

  sql = <<-EOQ
    select
      arn as id,
      left(id,8) as title,
      jsonb_build_object(
        'ARN', arn,
        'Key Manager', key_manager,
        'Creation Date', creation_date,
        'Enabled', enabled::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_kms_key
    where
      arn = any($1);
  EOQ

  param "kms_key_arns" {}
}