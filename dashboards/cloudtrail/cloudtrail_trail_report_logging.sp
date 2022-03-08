dashboard "aws_cloudtrail_trail_logging_report" {

  title         = "AWS CloudTrail Trail Logging Report"
  documentation = file("./dashboards/cloudtrail/docs/cloudtrail_trail_report_logging.md")

  tags = merge(local.cloudtrail_common_tags, {
    type     = "Report"
    category = "Logging"
  })

  container {

    card {
      sql   = query.aws_cloudtrail_trail_count.sql
      width = 2
    }

    card {
      sql = query.aws_cloudtrail_trail_logging_disabled_count.sql
      width = 2
    }

    card {
      sql = query.aws_cloudtrail_trail_log_file_validation_disabled_count.sql
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
      href = "/aws_insights.dashboard.aws_cloudtrail_trail_detail?input.trail_arn={{.row.ARN|@uri}}"
    }

    sql = query.aws_cloudtrail_trail_logging_table.sql
  
  }

}

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

query "aws_cloudtrail_trail_logging_table" {
  sql = <<-EOQ
    select
      t.name as "Name",
      case when t.is_logging then 'Enabled' else null end as "Logging",
      t.s3_bucket_name as "S3 Bucket Name",
      t.s3_key_prefix as "S3 Key Prefix",
      case when t.log_file_validation_enabled then 'Enabled' else null end as "Log File Validation",
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
      and t.region = t.home_region
    order by
      t.name;
  EOQ
}
