dashboard "backup_plan_detail" {

  title         = "AWS Backup Plan Detail"
  documentation = file("./dashboards/backup/docs/backup_plan_detail.md")

  tags = merge(local.backup_common_tags, {
    type = "Detail"
  })

  input "backup_plan_arn" {
    title = "Select a plan:"
    query = query.backup_plan_input
    width = 4
  }

  container {

    card {
      query = query.backup_plan_resource_assignment
      width = 3
      args  = [self.input.backup_plan_arn.value]
    }

  }

  with "backup_vaults_for_backup_plan" {
    query = query.backup_vaults_for_backup_plan
    args  = [self.input.backup_plan_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.backup_plan
        args = {
          backup_plan_arns = [self.input.backup_plan_arn.value]
        }
      }

      node {
        base = node.backup_plan_rule
        args = {
          backup_plan_arns = [self.input.backup_plan_arn.value]
        }
      }

      node {
        base = node.backup_selection
        args = {
          backup_plan_arns = [self.input.backup_plan_arn.value]
        }
      }

      node {
        base = node.backup_vault
        args = {
          backup_vault_arns = with.backup_vaults_for_backup_plan.rows[*].backup_vault_arn
        }
      }

      edge {
        base = edge.backup_plan_to_backup_rule
        args = {
          backup_plan_arns = [self.input.backup_plan_arn.value]
        }
      }

      edge {
        base = edge.backup_plan_rule_to_backup_vault
        args = {
          backup_plan_arns = [self.input.backup_plan_arn.value]
        }
      }

      edge {
        base = edge.backup_selection_to_backup_plan
        args = {
          backup_plan_arns = [self.input.backup_plan_arn.value]
        }
      }
    }

  }

  container {

    container {

      table {
        title = "Overview"
        type  = "line"
        width = 3
        query = query.backup_plan_overview
        args  = [self.input.backup_plan_arn.value]
      }

      table {
        title = "Rules"
        width = 9
        query = query.backup_plan_rules
        args  = [self.input.backup_plan_arn.value]
      }

    }

  }

}

# Input queries

query "backup_plan_input" {
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

# With queries

query "backup_vaults_for_backup_plan" {
  sql = <<-EOQ
    with plan_details as (
      select
        arn,
        jsonb_array_elements(backup_plan -> 'Rules') as rule
      from
        aws_backup_plan
      where
        arn = $1
        and account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    ),
    vault_names as (
      select
        rule ->> 'TargetBackupVaultName' as vault_name
      from
        plan_details
    )
    select
      v.arn as backup_vault_arn
    from
      aws_backup_vault v
    join
      vault_names vn on v.name = vn.vault_name
    where
      v.account_id = split_part($1, ':', 5)
      and v.region = split_part($1, ':', 4);
  EOQ
}

query "backup_plan_resource_assignment" {
  sql = <<-EOQ
    with filtered_backup_plans as (
      select
        backup_plan_id
      from
        aws_backup_plan
      where
        arn = $1
        and account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    )
    select
      'Resource Assignments' as label,
      count(s.selection_name) as value
    from
      aws_backup_selection s
    join
      filtered_backup_plans p on s.backup_plan_id = p.backup_plan_id;
  EOQ
} 

# Other detail page queries

query "backup_plan_overview" {
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
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and arn = $1;
  EOQ
}

query "backup_plan_rules" {
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
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and arn = $1;
  EOQ
}
