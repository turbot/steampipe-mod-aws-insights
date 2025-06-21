dashboard "kms_key_dashboard" {

  title         = "AWS KMS Key Dashboard"
  documentation = file("./dashboards/kms/docs/kms_key_dashboard.md")

  tags = merge(local.kms_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.kms_key_count
      width = 2
      href  = dashboard.kms_key_inventory_report.url_path
    }

    card {
      query = query.kms_customer_managed_key_count
      width = 2
    }

    # Assessments
    card {
      query = query.kms_key_disabled_count
      width = 2
    }

    card {
      query = query.kms_cmk_rotation_disabled_count
      width = 2
      href  = dashboard.kms_key_lifecycle_report.url_path
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      query = query.kms_key_cost_mtd
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Enabled/Disabled Status"
      query = query.kms_key_disabled_status
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "CMK Rotation Status"
      query = query.kms_key_rotation_status
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Cost"
    width = 6

    table {
      width = 6
      title = "Forecast"
      query = query.kms_monthly_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.kms_key_cost_per_month
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Keys by Account"
      query = query.kms_key_by_account
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Region"
      query = query.kms_key_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by State"
      query = query.kms_key_by_state
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Age"
      query = query.kms_key_by_creation_month
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "kms_key_count" {
  sql = <<-EOQ
    select count(*) as "Keys" from aws_kms_key;
  EOQ
}

query "kms_customer_managed_key_count" {
  sql = <<-EOQ
    select
      count(*)as "Customer Managed Keys"
    from
      aws_kms_key
    where
      key_manager = 'CUSTOMER';
  EOQ
}

query "kms_key_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_kms_key
    where
      not enabled;
  EOQ
}

query "kms_cmk_rotation_disabled_count" {
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

query "kms_key_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_monthly
    where
      service = 'AWS Key Management Service'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp);
  EOQ
}

# Assessment Queries

query "kms_key_disabled_status" {
  sql = <<-EOQ
    select
      disabled_status,
      count(*)
    from (
      select
        case when enabled then
          'enabled'
        else
          'disabled'
        end disabled_status
      from
        aws_kms_key) as t
    group by
      disabled_status
    order by
      disabled_status desc;
  EOQ
}

query "kms_key_rotation_status" {
  sql = <<-EOQ
    select
      rotation_status,
      count(*)
    from (
      select
        case when key_rotation_enabled then
          'enabled'
        else
          'disabled'
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

# Cost Queries

query "kms_monthly_forecast_table" {
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

query "kms_key_cost_per_month" {
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

# Analysis Queries

query "kms_key_by_account" {
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

query "kms_key_by_region" {
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

query "kms_key_by_state" {
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

query "kms_key_by_creation_month" {
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
