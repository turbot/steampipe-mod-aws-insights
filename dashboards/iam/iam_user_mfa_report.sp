query "aws_iam_user_mfa_not_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'MFA Not Enabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
      not mfa_enabled;
  EOQ
}

dashboard "aws_iam_user_mfa_report" {

  title = "AWS IAM User MFA Report"

  container {

    card {
      sql   = query.aws_iam_user_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_user_mfa_not_enabled_count.sql
      width = 2
    }
  }

  container {

    table {
      column "Account ID" {
        display = "none"
      }
      sql = <<-EOQ
      select
        u.name as "User",
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
        u.account_id,
        u.mfa_enabled;
      EOQ
    }
  }
}
