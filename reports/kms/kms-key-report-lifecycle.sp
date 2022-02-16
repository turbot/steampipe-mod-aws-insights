query "aws_kms_key_rotation_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Rotation Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
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
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_kms_key
    where
      key_state = 'PendingDeletion'
  EOQ
}

dashboard "aws_kms_key_lifecycle_report" {

  title = "AWS KMS Key Lifecycle Report"

  container {

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
    sql = <<-EOQ
      select
        id as "Key",
        case when key_rotation_enabled then 'Enabled' else null end as "Rotation",
        key_state as "Key State",
        deletion_date as "Deletion Date",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_kms_key
    EOQ
  }

}
