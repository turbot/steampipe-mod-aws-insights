query "aws_iam_user_mfa_not_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'MFA Enabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_iam_user
    where
      not mfa_enabled
  EOQ
}

report "aws_iam_user_mfa_report" {
  title = "AWS IAM User MFA Report"

  container {

    card {
      sql   = query.aws_iam_user_mfa_not_enabled_count.sql
      width = 2
    }
  }

  container {
    table {
      sql = <<-EOQ
      select
        name as "User",
        mfa_enabled as "mfa status",
        account_id as "Account",
        arn as "ARN"
      from
        aws_iam_user
      order by
        account_id,
        mfa_enabled
      EOQ
    }
  }
}
