query "aws_cloudtrail_trail_logging_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and not is_logging;
  EOQ
}

dashboard "aws_cloudtrail_trail_logging_report" {
  title = "AWS CloudTrail Trail Logging Report"

  container {

    card {
      sql   = query.aws_cloudtrail_trail_count.sql
      width = 2
    }

    card {
      sql = query.aws_cloudtrail_trail_logging_disabled_count.sql
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
        case when is_logging then 'Enabled' else 'Disabled' end as "Logging",
        t.s3_bucket_name as "S3 Bucket Name",
        t.s3_key_prefix as "S3 Key Prefix",
        t.start_logging_time as "Start Logging Time",
        t.stop_logging_time as "Stop Logging Time",
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
