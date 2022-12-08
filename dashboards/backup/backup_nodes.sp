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
    where
      arn = any($1);
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
        where
          arn = any($1)
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
    where
      arn = any($1);
  EOQ

  param "backup_vault_arns" {}
}