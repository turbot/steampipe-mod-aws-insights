query "aws_cloudtrail_trail_count" {
  sql = <<-EOQ
    select
      count(*) as "Trails"
    from
      aws_cloudtrail_trail
    where
      region = home_region;
  EOQ
}

query "aws_cloudtrail_regional_trail_count" {
  sql = <<-EOQ
    select
      count(*) as "Regional Trails"
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and not is_multi_region_trail;
  EOQ
}

query "aws_cloudtrail_trail_multi_region_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Multi-Region Trails' as label
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and is_multi_region_trail;
  EOQ
}

query "aws_cloudtrail_trail_log_file_validation_disabled_count" {
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

query "aws_cloudtrail_trail_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_cloudtrail_trail
    where
      home_region = region
      and kms_key_id is null;
  EOQ
}

# Assessments
query "aws_cloudtrail_trail_log_file_validation_status" {
  sql = <<-EOQ
    select
      log_file_validation_status,
      count(*)
    from (
      select
        case when log_file_validation_enabled then
          'Enabled'
        else
          'Disabled'
        end log_file_validation_status
      from
        aws_cloudtrail_trail
      where
        region = home_region) as t
    group by
      log_file_validation_status
    order by
      log_file_validation_status desc
  EOQ
}

query "aws_cloudtrail_trail_encryption_status" {
  sql = <<-EOQ
    with trail_encryption_status as (
      select
        name as trail_name,
        case
          when kms_key_id is null then 'Disabled'
          else 'Enabled'
        end as encryption_status
      from
        aws_cloudtrail_trail
      where
        home_region = region
    )
    select
      encryption_status,
      count(*)
    from
      trail_encryption_status
    group by encryption_status;
  EOQ
}

query "aws_cloudtrail_trail_logging_status" {
  sql = <<-EOQ
    with trail_logging_status as (
      select
        name as trail_name,
        case
          when not is_logging then 'Disabled'
          else 'Enabled'
        end as logging_status
      from
        aws_cloudtrail_trail
      where
        home_region = region
    )
    select
      logging_status,
      count(*)
    from
      trail_logging_status
    group by logging_status;
  EOQ
}

query "aws_cloudtrail_trail_bucket_publicly_accessible" {
  sql = <<-EOQ
    with public_bucket_data as (
      select
        t.s3_bucket_name as name,
        b.arn,
        t.region,
        t.account_id,
        count(acl_grant) filter (where acl_grant -> 'Grantee' ->> 'URI' like '%acs.amazonaws.com/groups/global/AllUsers') as all_user_grants,
        count(acl_grant) filter (where acl_grant -> 'Grantee' ->> 'URI' like '%acs.amazonaws.com/groups/global/AuthenticatedUsers') as auth_user_grants,
        count(s) filter (where s ->> 'Effect' = 'Allow' and  p = '*' ) as anon_statements
      from
        aws_cloudtrail_trail as t
      left join aws_s3_bucket as b on t.s3_bucket_name = b.name
      left join jsonb_array_elements(acl -> 'Grants') as acl_grant on true
      left join jsonb_array_elements(policy_std -> 'Statement') as s  on true
      left join jsonb_array_elements_text(s -> 'Principal' -> 'AWS') as p  on true
      where
        t.region = t.home_region
      group by
        t.s3_bucket_name,
        b.arn,
        t.region,
        t.account_id
    ),
    bucket_status as (
      select
        case
          when all_user_grants > 0  or auth_user_grants > 0 or anon_statements > 0 then 'Public'
          else 'Not Public'
        end as bucket_publicly_accessible_status
      from
        public_bucket_data
    )
    select
      bucket_publicly_accessible_status,
      count(*) as table_count
    from
      bucket_status
    group by bucket_publicly_accessible_status;
  EOQ
}

query "aws_cloudtrail_trail_cloudwatch_log_integration_status" {
  sql = <<-EOQ
    with cloudwatch_log_integration_status as (
      select
        case
          when log_group_arn != 'null' and ((latest_delivery_time) > current_date - 1) then 'Integrated'
          else 'Not Integrated'
        end as integration_status
      from
        aws_cloudtrail_trail
      where
        region = home_region
    )
    select
      integration_status,
      count(*) as trail_count
    from
      cloudwatch_log_integration_status
    group by integration_status;
  EOQ
}

#Costs
query "aws_cloudtrail_trail_monthly_forecast_table" {
  sql = <<-EOQ
    with monthly_costs as (
      select
        period_start,
        period_end,
        case
          when date_trunc('month', period_start) = date_trunc('month', CURRENT_DATE::timestamp) then 'Month to Date'
          when date_trunc('month', period_start) = date_trunc('month', CURRENT_DATE::timestamp - interval '1 month') then 'Previous Month'
          else to_char (period_start, 'Month')
        end as period_label,
        period_end::date - period_start::date as days,
        sum(unblended_cost_amount)::numeric::money as unblended_cost_amount,
        (sum(unblended_cost_amount) / (period_end::date - period_start::date ) )::numeric::money as average_daily_cost,
        date_part('days', date_trunc ('month', period_start) + '1 MONTH'::interval  - '1 DAY'::interval ) as days_in_month,
        sum(unblended_cost_amount) / (period_end::date - period_start::date ) * date_part('days', date_trunc ('month', period_start) + '1 MONTH'::interval  - '1 DAY'::interval )::numeric::money  as forecast_amount
      from
        aws_cost_by_service_usage_type_monthly as c
      where
        service = 'AWS CloudTrail'
        and date_trunc('month', period_start) >= date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
      group by
        period_start,
        period_end
    )
    select
      period_label as "Period",
      unblended_cost_amount as "Cost",
      average_daily_cost as "Daily Avg Cost"
    from
      monthly_costs
    union all
    select
      'This Month (Forecast)' as "Period",
      (select forecast_amount from monthly_costs where period_label = 'Month to Date') as "Cost",
      (select average_daily_cost from monthly_costs where period_label = 'Month to Date') as "Daily Avg Cost";
  EOQ
}

query "aws_cloudtrail_trail_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'AWS CloudTrail'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis
query "aws_cloudtrail_trail_count_per_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(t.*) as "Trails"
    from
      aws_cloudtrail_trail as t,
      aws_account as a
    where
      a.account_id = t.account_id
      and t.region = t.home_region
    group by a.title
    order by a.title;
  EOQ
}

query "aws_cloudtrail_trail_count_per_region" {
  sql = <<-EOQ
    with trail_count as (
      select
        arn,
        region
      from
        aws_cloudtrail_trail
      where
        region = home_region
        and not is_multi_region_trail
      union
      select
        arn,
        region
      from
        aws_cloudtrail_trail
      where
        region = home_region
        and is_multi_region_trail
    )
    select
      region,
      count(*) as "Trails"
    from
      trail_count as t
    group by region
    order by region;
  EOQ
}

query "aws_cloudtrail_regional_trail_count_per_region" {
  sql = <<-EOQ
    select
      region,
      count(*) as "Trails"
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and not is_multi_region_trail
    group by region
    order by region;
  EOQ
}

query "aws_cloudtrail_multi_region_trail_count_per_account" {
  sql = <<-EOQ
    with multi_region_trails as (
      select
        arn,
        account_id
      from
        aws_cloudtrail_trail
      where
        region = home_region
        and is_multi_region_trail
    )
    select
      a.title as "Account",
      count(t.*) as "Trails"
    from
      multi_region_trails as t,
      aws_account as a
    where
      a.account_id = t.account_id
    group by a.title
    order by a.title;
  EOQ
}

dashboard "aws_cloudtrail_trail_dashboard" {
  title = "AWS CloudTrail Trail Dashboard"

  tags = merge(local.cloudtrail_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.aws_cloudtrail_trail_count.sql
      width = 2
    }

    card {
      sql   = query.aws_cloudtrail_regional_trail_count.sql
      width = 2
    }

    card {
      sql   = query.aws_cloudtrail_trail_multi_region_count.sql
      width = 2
    }

    card {
      sql   = query.aws_cloudtrail_trail_log_file_validation_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.aws_cloudtrail_trail_unencrypted_count.sql
      width = 2
    }

    # Costs
    card {
      width = 2
      type  = "info"
      icon  = "currency-dollar"
      sql   = <<-EOQ
        select
          'Cost - MTD' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_monthly
        where
          service = 'AWS CloudTrail'
          and period_end > date_trunc('month', CURRENT_DATE::timestamp);
      EOQ
    }

  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Log File Validation Status"
      type  = "donut"
      width = 4
      sql   = query.aws_cloudtrail_trail_log_file_validation_status.sql
    }

    chart {
      title = "Encryption Status"
      type  = "donut"
      width = 4
      sql   = query.aws_cloudtrail_trail_encryption_status.sql
    }

    chart {
      title = "Logging Status"
      type  = "donut"
      width = 4
      sql   = query.aws_cloudtrail_trail_logging_status.sql
    }

    chart {
      title = "Trail Bucket Public Access Status"
      type  = "donut"
      width = 4
      sql   = query.aws_cloudtrail_trail_bucket_publicly_accessible.sql
    }

    chart {
      title = "Cloudwatch Log Integration Status"
      type  = "donut"
      width = 4
      sql   = query.aws_cloudtrail_trail_cloudwatch_log_integration_status.sql
    }

  }

  container {
    title = "Cost"
    width = 6

    # Costs
    table  {
      width = 6
      title = "Forecast"
      sql   = query.aws_cloudtrail_trail_monthly_forecast_table.sql
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      sql   = query.aws_cloudtrail_trail_cost_per_month.sql
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Trails by Account"
      type  = "column"
      width = 3
      sql   = query.aws_cloudtrail_trail_count_per_account.sql
    }

    chart {
      title = "Trails by Region"
      type  = "column"
      width = 3
      sql   = query.aws_cloudtrail_trail_count_per_region.sql
    }

    chart {
      title = "Regional Trails by Region"
      type  = "column"
      width = 3
      sql   = query.aws_cloudtrail_regional_trail_count_per_region.sql
    }

    chart {
      title = "Multi-Region Trails by Account"
      type  = "column"
      width = 3
      sql   = query.aws_cloudtrail_multi_region_trail_count_per_account.sql
    }

  }

}