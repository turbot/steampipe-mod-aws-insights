edge "backup_plan_to_backup_vault" {
  title = "backup vault"

  sql = <<-EOQ
    select
      p.arn as from_id,
      v.arn as to_id
    from
      aws_backup_vault as v,
      aws_backup_plan as p,
      jsonb_array_elements(backup_plan -> 'Rules') as r
    where
      r ->> 'TargetBackupVaultName' = v.name
      and p.arn = any($1);
  EOQ

  param "backup_plan_arns" {}
}

edge "backup_plan_to_backup_selection" {
  title = "backup selection"

  sql = <<-EOQ
    select
      p.arn as from_id,
      s.arn as to_id
    from
      aws_backup_selection as s,
      aws_backup_plan as p
    where
      s.backup_plan_id = p.backup_plan_id
      and p.arn = any($1);
  EOQ

  param "backup_plan_arns" {}
}

edge "backup_vault_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      v.arn as from_id,
      k.arn as to_id
    from
      aws_backup_vault as v
      left join aws_kms_key as k on k.arn = v.encryption_key_arn
    where
      v.arn = any($1);
  EOQ

  param "backup_vault_arns" {}
}

edge "backup_vault_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      v.arn as from_id,
      t.topic_arn as to_id
    from
      aws_backup_vault as v
      left join aws_sns_topic as t on t.topic_arn = v.sns_topic_arn
    where
      arn = any($1);
  EOQ

  param "backup_vault_arns" {}
}