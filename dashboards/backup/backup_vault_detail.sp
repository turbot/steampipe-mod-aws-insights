dashboard "backup_vault_detail" {

  title         = "AWS Backup Vault Detail"
  documentation = file("./dashboards/backup/docs/backup_vault_detail.md")

  tags = merge(local.backup_common_tags, {
    type = "Detail"
  })

  input "backup_vault_arn" {
    title = "Select a vault:"
    query = query.backup_vault_input
    width = 4
  }

  container {

    card {
      query = query.backup_vault_recovery_points
      width = 2
      args = {
        arn = self.input.backup_vault_arn.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "backup_plans" {
        sql = <<-EOQ
          select
            p.arn as backup_plan_arn
          from
            aws_backup_vault as v,
            aws_backup_plan as p,
            jsonb_array_elements(backup_plan -> 'Rules') as r
          where
            r ->> 'TargetBackupVaultName' = v.name
            and v.arn = $1
        EOQ

        args = [self.input.backup_vault_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            encryption_key_arn as kms_key_arn
          from
            aws_backup_vault
          where
            arn = $1;
        EOQ

        args = [self.input.backup_vault_arn.value]
      }

      with "sns_topics" {
        sql = <<-EOQ
          select
            sns_topic_arn
          from
            aws_backup_vault
          where
            arn = $1;
        EOQ

        args = [self.input.backup_vault_arn.value]
      }

      nodes = [
        node.backup_plan,
        node.backup_vault,
        node.kms_key,
        node.sns_topic
      ]

      edges = [
        edge.backup_plan_to_backup_vault,
        edge.backup_vault_to_kms_key,
        edge.backup_vault_to_sns_topic
      ]

      args = {
        backup_plan_arns      = with.backup_plans.rows[*].backup_plan_arn
        backup_vault_arns = [self.input.backup_vault_arn.value]
        kms_key_arns      = with.kms_keys.rows[*].kms_key_arn
        sns_topic_arns    = with.sns_topics.rows[*].sns_topic_arn
      }
    }
  }

  container {

    container {

      table {
        title = "Overview"
        type  = "line"
        width = 3
        query = query.backup_vault_overview
        args = {
          arn = self.input.backup_vault_arn.value
        }

      }

      table {
        title = "Policy"
        width = 9
        query = query.backup_vault_policy
        args = {
          arn = self.input.backup_vault_arn.value
        }

      }
    }
  }
}

query "backup_vault_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_backup_vault
    order by
      arn;
  EOQ
}

query "backup_vault_recovery_points" {
  sql = <<-EOQ
    select
      'Recovery Points' as label,
      number_of_recovery_points as value
    from
      aws_backup_vault
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "backup_vault_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      creation_date as "Creation Date",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_backup_vault
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "backup_vault_policy" {
  sql = <<-EOQ
    select
      s -> 'Action' as "Action",
      s -> 'Effect' as "Effect",
      s -> 'Resource' as "Resource",
      s -> 'Principal' as "Principal"
    from
      aws_backup_vault,
      jsonb_array_elements(policy_std -> 'Statement') as s
    where
      arn = $1;
  EOQ

  param "arn" {}
}
