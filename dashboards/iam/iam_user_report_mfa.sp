dashboard "iam_user_mfa_report" {

  title         = "AWS IAM User MFA Report"
  documentation = file("./dashboards/iam/docs/iam_user_report_mfa.md")

  tags = merge(local.iam_common_tags, {
    type     = "Report"
    category = "Security"
  })

  container {

    card {
      query = query.iam_user_count
      width = 2
    }

    card {
      query = query.iam_user_no_mfa_count
      width = 2
    }
  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "User Name" {
      href = "${dashboard.iam_user_detail.url_path}?input.user_arn={{.ARN | @uri}}"
    }

    query = query.iam_user_mfa_table
  }

}

query "iam_user_mfa_table" {
  sql = <<-EOQ
    select
      u.name as "User Name",
      case when u.mfa_enabled then 'Active' else null end as "MFA Status",
      a.title as "Account",
      a.account_id as "Account ID",
      u.arn as "ARN"
    from
      aws_iam_user as u,
      aws_account as a
    where
      u.account_id = a.account_id
    order by
      u.name;
  EOQ
}
