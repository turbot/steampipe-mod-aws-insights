query "aws_lambda_function_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
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

    column "Account ID" {
        display = "none"
    }

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
    EOQ
  }
}
