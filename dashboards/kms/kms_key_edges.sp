edge "kms_key_to_kms_alias" {
  title = "key"

  sql = <<-EOQ
    select
      a.arn as from_id,
      k.arn as to_id
    from
      aws_kms_alias as a
      join aws_kms_key as k
      on a.target_key_id = k.id
    where
      k.arn = any($1);
  EOQ

  param "kms_key_arns" {}
}
