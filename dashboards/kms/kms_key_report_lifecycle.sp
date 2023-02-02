dashboard "kms_key_lifecycle_report" {

  title         = "AWS KMS CMK Lifecycle Report"
  documentation = file("./dashboards/kms/docs/kms_key_report_lifecycle.md")

  tags = merge(local.kms_common_tags, {
    type     = "Report"
    category = "Lifecycle"
  })

  container {

    card {
      query = query.kms_customer_managed_key_count
      width = 3
    }

    card {
      query = query.kms_key_rotation_disabled_count
      width = 3
    }

    card {
      query = query.kms_cmk_pending_deletion_count
      width = 3
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Key ID" {
      href = "${dashboard.kms_key_detail.url_path}?input.key_arn={{.ARN | @uri}}"
    }

    query = query.kms_cmk_lifecycle_table
  }

}

query "kms_key_rotation_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Rotation Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_kms_key
    where
      not key_rotation_enabled
      and key_manager = 'CUSTOMER';
  EOQ
}

query "kms_cmk_pending_deletion_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Pending Deletion' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_kms_key
    where
      key_state = 'PendingDeletion'
      and key_manager = 'CUSTOMER';
  EOQ
}

query "kms_cmk_lifecycle_table" {
  sql = <<-EOQ
    select
      k.id as "Key ID",
      case when k.key_rotation_enabled then 'Enabled' else null end as "Key Rotation",
      k.key_state as "Key State",
      k.key_manager as "Key Manager",
      k.deletion_date as "Deletion Date",
      a.title as "Account",
      k.account_id as "Account ID",
      k.region as "Region",
      k.arn as "ARN"
    from
      aws_kms_key as k,
      aws_account as a
    where
      k.account_id = a.account_id
      and k.key_manager = 'CUSTOMER'
    order by
      k.id;
  EOQ
}
