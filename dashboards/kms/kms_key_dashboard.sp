query "aws_kms_key_count" {
  sql = <<-EOQ
    select count(*) as "Keys" from aws_kms_key;
  EOQ
}

query "aws_kms_key_customer_managed_count" {
  sql = <<-EOQ
    select
      count(*)as "Customer Managed Keys"
    from
      aws_kms_key
    where
      key_manager = 'CUSTOMER';
  EOQ
}

query "aws_inactive_kms_key_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Inactive' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_kms_key
    where
      not enabled;
  EOQ
}

query "aws_kms_key_rotation_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'CMK Rotation Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_kms_key
    where
      not key_rotation_enabled
      and key_manager = 'CUSTOMER';
  EOQ
}

# Assessments
query "aws_inactive_kms_key_status" {
  sql = <<-EOQ
    select
      inactive_status,
      count(*)
    from (
      select
        case when enabled then
          'Enabled'
        else
          'Disabled'
        end inactive_status
      from
        aws_kms_key) as t
    group by
      inactive_status
    order by
      inactive_status desc;
  EOQ
}

query "aws_kms_key_rotation_status" {
  sql = <<-EOQ
    select
      rotation_status,
      count(*)
    from (
      select
        case when key_rotation_enabled then
          'Enabled'
        else
          'Disabled'
        end rotation_status
      from
        aws_kms_key
      where
        key_manager = 'CUSTOMER') as t
    group by
      rotation_status
    order by
      rotation_status desc;
  EOQ
}

query "aws_kms_key_usage_status" {
  sql = <<-EOQ
    select
      key_usage,
      count(key_usage)
    from
      aws_kms_key
    group by
      key_usage;
  EOQ
}

# Cost
query "aws_kms_key_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'AWS Key Management Service'
    group by
      period_start
    order by
      period_start;
  EOQ
}

query "aws_kms_monthly_forecast_table" {
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
        aws_cost_by_service_monthly as c

      where
        service = 'AWS Key Management Service'
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

# Analysis
query "aws_kms_key_by_account" {

  sql = <<-EOQ
    select
      a.title as "Account",
      count(i.*) as "Keys"
    from
      aws_kms_key as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "aws_kms_key_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as "Keys"
    from
      aws_kms_key as i
    group by
      region;
  EOQ
}

query "aws_kms_key_by_state" {
  sql = <<-EOQ
    select
      key_state,
      count(key_state)
    from
      aws_kms_key
    group by
      key_state;
  EOQ
}

query "aws_kms_key_by_creation_month" {
  sql = <<-EOQ
    with keys as (
      select
        title,
        creation_date,
        to_char(creation_date,
          'YYYY-MM') as creation_month
      from
        aws_kms_key
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(creation_date)
                from keys)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    keys_by_month as (
      select
        creation_month,
        count(*)
      from
        keys
      group by
        creation_month
    )
    select
      months.month,
      keys_by_month.count
    from
      months
      left join keys_by_month on months.month = keys_by_month.creation_month
    order by
      months.month;
  EOQ
}

dashboard "aws_kms_key_dashboard" {

  title = "AWS KMS Key Dashboard"

  container {

    card {
      sql   = query.aws_kms_key_count.sql
      width = 2
    }

    card {
      sql   = query.aws_kms_key_customer_managed_count.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_inactive_kms_key_count.sql
      width = 2
    }

    card {
      sql   = query.aws_kms_key_rotation_enabled_count.sql
      width = 2
    }

    # Costs
    card {
      type = "info"
      icon = "currency-dollar"

      sql   = <<-EOQ
        select
          'Cost - MTD' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_monthly
        where
          service = 'AWS Key Management Service'
          and period_end > date_trunc('month', CURRENT_DATE::timestamp);
      EOQ
      width = 2
    }

  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Inactive/Active Status"
      sql   = query.aws_inactive_kms_key_status.sql
      type  = "donut"
      width = 4
    }

    chart {
      title = "CMK Rotation Status"
      sql   = query.aws_kms_key_rotation_status.sql
      type  = "donut"
      width = 4
    }

    chart {
      title = "Usage Status"
      sql   = query.aws_kms_key_usage_status.sql
      type  = "donut"
      width = 4
    }

  }

  container {
    title = "Cost"
    width = 6

    # Costs
    table {
      width = 6
      title = "Forecast"
      sql   = query.aws_kms_monthly_forecast_table.sql
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      sql   = query.aws_kms_key_cost_per_month.sql
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Keys by Account"
      sql   = query.aws_kms_key_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Region"
      sql   = query.aws_kms_key_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by State"
      sql   = query.aws_kms_key_by_state.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Age"
      sql   = query.aws_kms_key_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

}
