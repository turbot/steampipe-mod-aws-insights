dashboard "aws_lambda_function_public_access_report" {

  title = "AWS Lambda Function Public Access Report"

  tags = merge(local.lambda_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      sql   = query.aws_lambda_function_count.sql
      width = 2
    }

    card {
      sql = query.aws_lambda_function_public_count.sql
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

    column "Name" {
      href = "/aws_insights.dashboard.aws_lambda_function_detail?input.lambda_arn={{.row.ARN|@uri}}"
    }

    sql = query.aws_lambda_function_public_access_table.sql
  }

}

query "aws_lambda_function_public_access_table" {
  sql = <<-EOQ
    select
      f.name as "Name",
      case
        when
        f.policy_std -> 'Statement' ->> 'Effect' = 'Allow'
        and (f.policy_std -> 'Statement' ->> 'Prinipal' = '*'
        or ( f.policy_std -> 'Principal' -> 'AWS' ) :: text = '*')
        then 'Public' else 'Private' end as "Public/Private",
      a.title as "Account",
      f.account_id as "Account ID",
      f.region as "Region",
      f.arn as "ARN"
    from
      aws_lambda_function as f,
      aws_account as a
    where
      f.account_id = a.account_id
    order by
      f.name;
  EOQ
}
