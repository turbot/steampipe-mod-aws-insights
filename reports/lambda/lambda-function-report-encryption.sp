query "aws_lambda_function_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_lambda_function
    where
      kms_key_arn is null
  EOQ
}

dashboard "aws_lambda_function_encryption_dashboard" {

  title = "AWS Lambda Function Encryption Report"

  container {

    card {
      sql = query.aws_lambda_function_unencrypted_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        name as "Function",
        case when kms_key_arn is not null then 'Enabled' else null end as "Encryption",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_lambda_function
    EOQ
  }
}
