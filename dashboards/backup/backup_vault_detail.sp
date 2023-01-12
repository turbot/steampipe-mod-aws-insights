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
      args  = [self.input.backup_vault_arn.value]
    }

  }

  with "backup_plans_for_backup_vault" {
    query = query.backup_plans_for_backup_vault
    args  = [self.input.backup_vault_arn.value]
  }

  with "kms_keys_for_backup_vault" {
    query = query.kms_keys_for_backup_vault
    args  = [self.input.backup_vault_arn.value]
  }

  with "sns_topics_for_backup_vault" {
    query = query.sns_topics_for_backup_vault
    args  = [self.input.backup_vault_arn.value]
  }

  with "policy_std_for_backup_vault" {
    query = query.policy_std_for_backup_vault
    args  = [self.input.backup_vault_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.backup_plan
        args = {
          backup_plan_arns = with.backup_plans_for_backup_vault.rows[*].backup_plan_arn
        }
      }

      node {
        base = node.backup_vault
        args = {
          backup_vault_arns = [self.input.backup_vault_arn.value]
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_backup_vault.rows[*].kms_key_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics_for_backup_vault.rows[*].sns_topic_arn
        }
      }

      edge {
        base = edge.backup_plan_to_backup_vault
        args = {
          backup_plan_arns = with.backup_plans_for_backup_vault.rows[*].backup_plan_arn
        }
      }

      edge {
        base = edge.backup_vault_to_kms_key
        args = {
          backup_vault_arns = [self.input.backup_vault_arn.value]
        }
      }

      edge {
        base = edge.backup_vault_to_sns_topic
        args = {
          backup_vault_arns = [self.input.backup_vault_arn.value]
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
        query = query.backup_vault_overview
        args  = [self.input.backup_vault_arn.value]
      }
    }

    graph {
      title = "Resource Policy"
      base  = graph.iam_resource_policy_structure
      args = {
        policy_std = with.policy_std_for_backup_vault.rows[0].policy_std
      }
    }

  }

}

# Input queries

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

# With queries

query "backup_plans_for_backup_vault" {
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
}

query "kms_keys_for_backup_vault" {
  sql = <<-EOQ
    select
      encryption_key_arn as kms_key_arn
    from
      aws_backup_vault
    where
      encryption_key_arn is not null
      and arn = $1;
  EOQ
}

query "sns_topics_for_backup_vault" {
  sql = <<-EOQ
    select
      sns_topic_arn
    from
      aws_backup_vault
    where
      sns_topic_arn is not null
      and arn = $1;
  EOQ
}

query "policy_std_for_backup_vault" {
  sql = <<-EOQ
    select
      policy_std
    from
      aws_backup_vault
    where
      arn = $1;
  EOQ
}

# Card queries

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
}

# Other detail page queries

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
}
