query "aws_cloudtrail_trail_log_file_validation_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Log File Validation Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and not log_file_validation_enabled;
  EOQ
}

dashboard "aws_cloudtrail_trail_log_file_validation_report" {
  title = "AWS CloudTrail Trail Log File Validation Report"

  container {

    card {
      sql   = query.aws_cloudtrail_trail_count.sql
      width = 2
    }

    card {
      sql = query.aws_cloudtrail_trail_log_file_validation_count.sql
      width = 2
    }
  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      select
        t.name as "Name",
        case when log_file_validation_enabled then 'Enabled' else 'Disabled' end as "Logging",
        a.title as "Account",
        t.account_id as "Account ID",
        t.region as "Region",
        t.arn as "ARN"
      from
        aws_cloudtrail_trail as t,
        aws_account as a
      where
        t.account_id = a.account_id
        and t.region = t.home_region;
    EOQ
  }
  
}
