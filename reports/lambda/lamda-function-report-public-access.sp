query "aws_lambda_function_public_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Lambda Functions' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_lambda_function
    where
      policy_std -> 'Statement' ->> 'Effect' = 'Allow'
    and (
      policy_std -> 'Statement' ->> 'Prinipal' = '*'
      or ( policy_std -> 'Principal' -> 'AWS' ) :: text = '*')
  EOQ
}

dashboard "aws_lambda_function_public_access_report" {

  title = "AWS Lambda Function Public Access Report"

  container {

    card {
      sql = query.aws_lambda_function_public_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        name as "Lambda",
        case
          when
          policy_std -> 'Statement' ->> 'Effect' = 'Allow'
          and (policy_std -> 'Statement' ->> 'Prinipal' = '*'
          or ( policy_std -> 'Principal' -> 'AWS' ) :: text = '*')
       then 'Public' else 'Private' end as "Public/Private",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_lambda_function
    EOQ
  }
}
