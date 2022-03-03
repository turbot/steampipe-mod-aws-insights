dashboard "aws_cloudtrail_trail_log_file_validation_report" {
  
  title = "AWS CloudTrail Trail Log File Validation Report"

  tags = merge(local.cloudtrail_common_tags, {
    type     = "Report"
    category = "Log File Validation"
  })

  container {

    card {
      sql   = query.aws_cloudtrail_trail_count.sql
      width = 2
    }

    card {
      sql = query.aws_cloudtrail_trail_log_file_validation_disabled_count.sql
      width = 2
    }

  }

  container {

    table {
      column "Account ID" {
        display = "none"
      }

      sql = query.aws_cloudtrail_trail_log_file_validation_table.sql
      
    }
  }

}

query "aws_cloudtrail_trail_log_file_validation_table" {
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
      and t.region = t.home_region
    order by
      t.name;
  EOQ
}
