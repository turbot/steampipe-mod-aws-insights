dashboard "backup_plan_detail" {

  title         = "AWS Backup Plan Detail"
  documentation = file("./dashboards/backup/docs/backup_plan_detail.md")

  tags = merge(local.backup_common_tags, {
    type = "Detail"
  })

  input "backup_plan_arn" {
    title = "Select a plan:"
    query = query.aws_backup_plan_input
    width = 4
  }

  container {

    card {
      query = query.aws_backup_plan_resource_assignment
      width = 2
      args = {
        arn = self.input.backup_plan_arn.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_backup_plan_node,
        node.aws_backup_plan_to_backup_vault_node,
        node.aws_backup_plan_to_backup_selection_node
      ]

      edges = [
        edge.aws_backup_plan_to_backup_vault_edge,
        edge.aws_backup_plan_to_backup_selection_edge
      ]

      args = {
        arn = self.input.backup_plan_arn.value
      }
    }
  }

  container {

    container {

      table {
        title = "Overview"
        type  = "line"
        width = 3
        query = query.aws_backup_plan_overview
        args = {
          arn = self.input.backup_plan_arn.value
        }

      }

      table {
        title = "Rules"
        width = 9
        query = query.aws_backup_plan_rules
        args = {
          arn = self.input.backup_plan_arn.value
        }

      }
    }
  }
}

query "aws_backup_plan_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_backup_plan
    where
      deletion_date is null
    order by
      arn;
  EOQ
}

query "aws_backup_plan_resource_assignment" {
  sql = <<-EOQ
    select
      'Resource Assignments' as label,
      count(selection_name) as value
    from
      aws_backup_selection as s,
      aws_backup_plan as p
    where
      s.backup_plan_id = p.backup_plan_id
      and p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_backup_plan_node" {
  category = category.aws_backup_plan

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
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_backup_plan_to_backup_vault_node" {
  category = category.aws_backup_vault

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
      name in
      (
        select
          r ->> 'TargetBackupVaultName'
        from
          aws_backup_plan,
          jsonb_array_elements(backup_plan -> 'Rules') as r
        where
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_backup_plan_to_backup_vault_edge" {
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
      and p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_backup_plan_to_backup_selection_node" {
  category = category.aws_backup_selection

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
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_backup_plan_to_backup_selection_edge" {
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
      and p.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_backup_plan_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      creation_date as "Creation Date",
      last_execution_date as "Last Execution Date",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_backup_plan
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_backup_plan_rules" {
  sql = <<-EOQ
    select
      r ->> 'RuleId' as "Rule ID",
      r ->> 'RuleName' as "Rule Name",
      r -> 'Lifecycle' as "Lifecycle",
      r -> 'CopyActions' as "Copy Actions",
      r -> 'RecoveryPointTags' as "Recovery Point Tags",
      r -> 'ScheduleExpression' as "Schedule Expression",
      r -> 'StartWindowMinutes' as "Start Window Minutes",
      r -> 'EnableContinuousBackup' as "EnableContinuousBackup",
      r -> 'CompletionWindowMinutes' as "Completion Window Minutes"
    from
      aws_backup_plan,
      jsonb_array_elements(backup_plan -> 'Rules') as r
    where
      arn = $1;
  EOQ

  param "arn" {}
}
