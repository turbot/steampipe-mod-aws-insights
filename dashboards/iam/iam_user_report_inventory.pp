dashboard "iam_user_inventory_report" {

  title         = "AWS IAM User Inventory Report"
  documentation = file("./dashboards/iam/docs/iam_user_report_inventory.md")

  tags = merge(local.iam_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.iam_user_count
      width = 2
    }

  }

  table {
    column "Name" {
      href = "${dashboard.iam_user_detail.url_path}?input.user_arn={{.'ARN' | @uri}}"
    }

    query = query.iam_user_inventory_table
  }

}

query "iam_user_inventory_table" {
  sql = <<-EOQ
    select
      u.name as "Name",
      u.create_date as "Create Date",
      u.mfa_enabled as "MFA Enabled",
      u.password_last_used as "Password Last Used",
      u.tags as "Tags",
      u.arn as "ARN",
      u.account_id as "Account ID",
      a.title as "Account"
    from
      aws_iam_user as u
      left join aws_account as a on u.account_id = a.account_id
    order by
      u.name;
  EOQ
} 