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
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
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
      join aws_kms_key as k on a.target_key_id = k.id
      join unnest($1::text[]) as b on k.arn = b and k.account_id = split_part(b, ':', 5) and k.region = split_part(b, ':', 4);
  EOQ

  param "kms_key_arns" {}
}
