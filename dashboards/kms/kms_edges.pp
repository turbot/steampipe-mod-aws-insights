edge "kms_key_to_kms_alias" {
  title = "key"

  sql = <<-EOQ
    select
      a.arn as from_id,
      k.arn as to_id
    from
      aws_kms_alias as a
      join aws_kms_key as k on a.target_key_id = k.id
      join unnest($1::text[]) as b on k.arn = b and k.account_id = split_part(b, ':', 5) and k.region = split_part(b, ':', 4);
  EOQ

  param "kms_key_arns" {}
}

