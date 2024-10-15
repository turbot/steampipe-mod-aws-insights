dashboard "lambda_function_public_access_report" {

  title         = "AWS Lambda Function Public Access Report"
  documentation = file("./dashboards/lambda/docs/lambda_function_report_public_access.md")

  tags = merge(local.lambda_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      query = query.lambda_function_count
      width = 3
    }

    card {
      query = query.lambda_function_public_count
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

    column "Name" {
      href = "${dashboard.lambda_function_detail.url_path}?input.lambda_arn={{.ARN | @uri}}"

    }

    query = query.lambda_function_public_access_table
  }

}

query "lambda_function_public_access_table" {
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
