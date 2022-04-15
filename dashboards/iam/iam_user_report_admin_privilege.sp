dashboard "aws_iam_user_admin_privilege_report" {

  title = "AWS IAM User Admin Privilege Report"

  tags = merge(local.iam_common_tags, {
    type     = "Report"
    category = "Permissions"
  })

  container {

    card {
      query = query.aws_iam_user_count
      width = 2
    }

    card {
      query = query.iam_users_with_admin_privilege_count
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
      href = "/aws_insights.dashboard.aws_iam_user_detail?input.user_arn={{.row.ARN | @uri}}"
    }

    query = query.iam_users_with_admin_privilege_report
  }

}
