edge "backup_plan_to_backup_rule" {
  title = "backup rule"

  sql = <<-EOQ
    select
      p.arn as from_id,
      r ->> 'RuleId' as to_id
    from
      aws_backup_plan as p,
      jsonb_array_elements(backup_plan -> 'Rules') as r
    where
      p.arn = any($1);
  EOQ

  param "backup_plan_arns" {}
}

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

edge "backup_plan_rule_to_backup_vault" {
  title = "backup vault"

  sql = <<-EOQ
    select
      r ->> 'RuleId' as from_id,
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

edge "backup_selection_to_backup_plan" {
  title = "backup plan"

  sql = <<-EOQ
    select
      s.arn as from_id,
      p.arn as to_id
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
      arn as from_id,
      encryption_key_arn as to_id
    from
      aws_backup_vault as v
    where
      arn = any($1);
  EOQ

  param "backup_vault_arns" {}
}

edge "backup_vault_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      arn as from_id,
      sns_topic_arn as to_id
    from
      aws_backup_vault
    where
      arn = any($1);
  EOQ

  param "backup_vault_arns" {}
}
