dashboard "aws_lambda_function_encryption_report" {

  title = "AWS Lambda Function Encryption Report"

  tags = merge(local.lambda_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      sql   = query.aws_lambda_function_count.sql
      width = 2
    }

    card {
      sql = query.aws_lambda_function_unencrypted_count.sql
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

    sql = query.aws_lambda_function_encryption_table.sql
    }

}

query "aws_lambda_function_encryption_table" {
  sql = <<-EOQ
    select
      f.name as "Name",
      case when f.kms_key_arn is not null then 'Enabled' else null end as "Encryption",
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
