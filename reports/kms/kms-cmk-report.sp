query "aws_kms_cmk_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'CMK' as label
    from
      aws_kms_key
    where
      key_manager = 'CUSTOMER'
  EOQ
}

dashboard "aws_kms_cmk_report" {

  title = "AWS KMS CMK Report"

  container {

    card {
      sql = query.aws_kms_cmk_count.sql
      width = 2
    }

  }

  table {
    sql = <<-EOQ
      select
        id as "Key",
        case when enabled then 'Active' else 'InActive' end as "Active/InActive",
        case when key_rotation_enabled then 'Enabled' else 'Disabled' end as "Key Rotation",
        key_state as "State",
        customer_master_key_spec as "Customer Master Key spec",
        deletion_date as "Deletion Date",
        aliases as "Aliases",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_kms_key
    EOQ
  }

}
