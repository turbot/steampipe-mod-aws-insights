query "aws_lambda_function_public_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Lambda Functions' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
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

    column "Account ID" {
        display = "none"
    }

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
    EOQ
  }
}
