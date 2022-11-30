dashboard "lambda_function_encryption_report" {

  title         = "AWS Lambda Function Encryption Report"
  documentation = file("./dashboards/lambda/docs/lambda_function_report_encryption.md")

  tags = merge(local.lambda_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.lambda_function_count
      width = 2
    }

    card {
      query = query.lambda_function_unencrypted_count
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
      href = "/aws_insights.dashboard.lambda_function_detail?input.lambda_arn={{.ARN | @uri}}"
    }

    query = query.lambda_function_encryption_table
  }

}

query "lambda_function_encryption_table" {
  sql = <<-EOQ
    select
      f.name as "Name",
      case when f.kms_key_arn is not null then 'Enabled' else null end as "Encryption",
      f.kms_key_arn as "KMS Key ARN",
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
