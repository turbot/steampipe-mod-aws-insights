dashboard "aws_iam_user_mfa_report" {

  title = "AWS IAM User MFA Report"

  tags = merge(local.iam_common_tags, {
    type     = "Report"
    category = "Security"
  })

  container {

    card {
      sql   = query.aws_iam_user_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_user_no_mfa_count.sql
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
      href = "/aws_insights.dashboard.aws_iam_user_detail?input.user_arn={{.row.ARN|@uri}}"
    }

    sql = query.aws_iam_user_mfa_table.sql
  }

}

query "aws_iam_user_mfa_table" {
  sql = <<-EOQ
    select
      u.name as "User Name",
      u.mfa_enabled as "MFA Active",
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
