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

node "kms_key_alias" {
  category = category.kms_alias

  sql = <<-EOQ
    select
      a.arn as id,
      a.title as title,
      jsonb_build_object(
        'ARN', a.arn,
        'Create Date', a.creation_date,
        'Account ID', a.account_id,
        'Region', a.region
      ) as properties
    from
      aws_kms_alias as a
      join aws_kms_key as k
      on a.target_key_id = k.id
    where
      k.arn = any($1);
  EOQ

  param "kms_key_arns" {}
}
