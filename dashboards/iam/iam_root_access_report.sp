dashboard "iam_root_access_report" {

  title         = "AWS IAM Root Access Report"
  documentation = file("./dashboards/iam/docs/iam_root_access_report.md")

  tags = merge(local.iam_common_tags, {
    type     = "Report"
    category = "Credential Report"
  })

  container {

    card {
      width = 2
      query = query.iam_root_access_keys_count
    }

    card {
      width = 2
      query = query.iam_accounts_without_root_mfa
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    query = query.iam_root_access_keys_table
  }

}

query "iam_root_access_keys_count" {
  sql = <<-EOQ
    select
      sum(account_access_keys_present) as value,
      'Root Access Keys' as label,
      case when sum(account_access_keys_present) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_account_summary;
  EOQ
}

query "iam_accounts_without_root_mfa" {
  sql = <<-EOQ
    select
      count(*) filter (where not account_mfa_enabled) as value,
      'Accounts Without Root MFA' as label,
      case when count(*) filter (where not account_mfa_enabled) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_account_summary;
  EOQ
}

query "iam_root_access_keys_table" {
  sql = <<-EOQ
    select
      a.title as "Account",
      s.account_id as "Account ID",
      s.account_access_keys_present as "Root Keys",
      account_mfa_enabled as "Root MFA Enabled"
    from
      aws_iam_account_summary as s,
      aws_account as a
    where
      a.account_id = s.account_id
    order by
      a.title;
  EOQ
}

/*
 TODO: Can we find root logins in cloudtrail events??
  - join with cloudtrail table to find the log group?
  - bug: https://github.com/turbot/steampipe-plugin-aws/issues/902

select
  event_name,
  event_type,
  event_time,
  aws_region,
  error_code,
  error_message,
  event_id,
  user_type,
  additional_event_data,
  response_elements,
  jsonb_pretty(cloudtrail_event)
from
  aws_cloudtrail_trail_event
where
  log_group_name = 'aws-cloudtrail-logs' and event_name = 'ConsoleLogin'
*/
