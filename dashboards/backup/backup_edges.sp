edge "backup_plan_to_backup_rule" {
  title = "backup rule"

  sql = <<-EOQ
    select
      p.arn as from_id,
      r ->> 'RuleId' as to_id
    from
      aws_backup_plan as p
      join unnest($1::text[]) as a on p.arn = a and p.account_id = split_part(a, ':', 5) and p.region = split_part(a, ':', 4),
      jsonb_array_elements(backup_plan -> 'Rules') as r
  EOQ

  param "backup_plan_arns" {}
}

edge "backup_plan_to_backup_vault" {
  title = "backup vault"

  sql = <<-EOQ
    with backup_vaults as (
      select
       arn,
       name,
       region,
       account_id
      from
        aws_backup_vault
    )
    select
      p.arn as from_id,
      v.arn as to_id
    from
      backup_vaults as v,
      aws_backup_plan as p
      join unnest($1::text[]) as a on p.arn = a and p.account_id = split_part(a, ':', 5) and p.region = split_part(a, ':', 4),
      jsonb_array_elements(backup_plan -> 'Rules') as r
    where
      r ->> 'TargetBackupVaultName' = v.name;
  EOQ

  param "backup_plan_arns" {}
}


edge "backup_plan_rule_to_backup_vault" {
  title = "backup vault"

  sql = <<-EOQ
    with backup_vaults as (
      select
       arn,
       name,
       region,
       account_id
      from
        aws_backup_vault
    )
    select
      r ->> 'RuleId' as from_id,
      v.arn as to_id
    from
      backup_vaults as v,
      aws_backup_plan as p
      join unnest($1::text[]) as a on p.arn = a and p.account_id = split_part(a, ':', 5) and p.region = split_part(a, ':', 4),
      jsonb_array_elements(backup_plan -> 'Rules') as r
    where
      r ->> 'TargetBackupVaultName' = v.name;
  EOQ

  param "backup_plan_arns" {}
}

edge "backup_selection_to_backup_plan" {
  title = "backup plan"

  sql = <<-EOQ
    with backup_selection as (
      select
        backup_plan_id,
        arn,
        region,
        account_id
      from
        aws_backup_selection
    )
    select
      s.arn as from_id,
      p.arn as to_id
    from
      backup_selection as s,
      aws_backup_plan as p
      join unnest($1::text[]) as a on p.arn = a and p.account_id = split_part(a, ':', 5) and p.region = split_part(a, ':', 4)
    where
      s.backup_plan_id = p.backup_plan_id;
  EOQ

  param "backup_plan_arns" {}
}

# edge "backup_selection_to_backup_plan" {
#   title = "backup plan"

#   sql = <<-EOQ
#     select
#       s.arn as from_id,
#       p.arn as to_id
#     from
#       aws_backup_selection as s,
#       aws_backup_plan as p
#     where
#       s.backup_plan_id = p.backup_plan_id
#       and p.arn = any($1);
#   EOQ

#   param "backup_plan_arns" {}
# }

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
      join unnest($1::text[]) as a on p.arn = a and p.account_id = split_part(a, ':', 5) and p.region = split_part(a, ':', 4);
  EOQ

  param "backup_vault_arns" {}
}
