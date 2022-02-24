query "aws_kms_key_rotation_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Rotation Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_kms_key
    where
      not key_rotation_enabled
  EOQ
}

query "aws_kms_key_pending_deletion_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Pending Deletion' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_kms_key
    where
      key_state = 'PendingDeletion'
  EOQ
}

dashboard "aws_kms_key_lifecycle_dashboard" {

  title = "AWS KMS Key Lifecycle Report"

  container {

    card {
      sql   = query.aws_kms_key_count.sql
      width = 2
    }

    card {
      sql = query.aws_kms_key_rotation_disabled_count.sql
      width = 2
    }

    card {
      sql = query.aws_kms_key_pending_deletion_count.sql
      width = 2
    }

  }

  table {

    column "Account ID" {
        display = "none"
    }

    sql = <<-EOQ
      select
        v.id as "Key",
        case when v.key_rotation_enabled then 'Enabled' else null end as "Rotation",
        v.key_state as "Key State",
        v.deletion_date as "Deletion Date",
        a.title as "Account",
        v.account_id as "Account ID",
        v.region as "Region",
        v.arn as "ARN"
      from
        aws_kms_key as v,
        aws_account as a
      where
        v.account_id = a.account_id
    EOQ
    
  }

}
