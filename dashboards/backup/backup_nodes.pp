node "backup_plan" {
  category = category.backup_plan

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object (
        'ARN', arn,
        'Name', name,
        'Creation Date', creation_date,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_backup_plan
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "backup_plan_arns" {}
}

node "backup_plan_rule" {
  category = category.backup_plan_rule

  sql = <<-EOQ
    select
      r ->> 'RuleId' as id,
      r ->> 'RuleName' as title,
      jsonb_build_object (
        'Schedule Expression', r ->> 'ScheduleExpression',
        'Start Window Minutes', r ->> 'StartWindowMinutes',
        'Completion Window Minutes', r ->> 'CompletionWindowMinutes',
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_backup_plan
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4),
      jsonb_array_elements(backup_plan -> 'Rules') as r;
  EOQ

  param "backup_plan_arns" {}
}

node "backup_selection" {
  category = category.backup_selection

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Name', selection_name,
        'Creation Date', creation_date,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_backup_selection
    where
      backup_plan_id in
      (
        select
          backup_plan_id
        from
          aws_backup_plan
          join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
      );
  EOQ

  param "backup_plan_arns" {}
}

node "backup_vault" {
  category = category.backup_vault

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object (
        'ARN', arn,
        'Name', name,
        'Creation Date', creation_date,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_backup_vault
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "backup_vault_arns" {}
}
