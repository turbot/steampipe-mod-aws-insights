
dashboard "sns_topic_dashboard" {

  title         = "AWS SNS Topic Dashboard"
  documentation = file("./dashboards/sns/docs/sns_topic_dashboard.md")

  tags = merge(local.sns_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.sns_topic_count
      width = 3
    }

    # Assessments
    card {
      query = query.sns_topic_encrypted_count
      width = 3
      href  = dashboard.sns_topic_encryption_report.url_path
    }

    card {
      query = query.sns_topic_by_subscription_count
      width = 3
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 3
      query = query.sns_topic_cost_mtd
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      query = query.sns_topic_by_encryption_status
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
      title = "Subscriptions Status"
      query = query.sns_topic_by_subscription_status
      type  = "donut"
      width = 4

      series "count" {
        point "with subscriptions" {
          color = "ok"
        }
        point "no subscriptions" {
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
      query = query.sns_topic_monthly_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.sns_topic_cost_per_month
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Topics by Account"
      query = query.sns_topic_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Topics by Region"
      query = query.sns_topic_by_region
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "sns_topic_count" {
  sql = <<-EOQ
    select count(*) as "Topics" from aws_sns_topic;
  EOQ
}

query "sns_topic_encrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_sns_topic
    where
      kms_master_key_id is null;
  EOQ
}

query "sns_topic_by_subscription_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'No Subscriptions' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_sns_topic
    where
      subscriptions_confirmed::int = 0;
  EOQ
}

query "sns_topic_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_usage_type_monthly as c
    where
      service = 'Amazon Simple Notification Service'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp);
  EOQ
}

# Assessment Queries

query "sns_topic_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select kms_master_key_id,
        case when kms_master_key_id is not null then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_sns_topic) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "sns_topic_by_subscription_status" {
  sql = <<-EOQ
    select
      subscription_status,
      count(*)
    from (
      select subscriptions_confirmed,
        case when subscriptions_confirmed::int = 0 then
          'no subscriptions'
        else
          'with subscriptions'
        end subscription_status
      from
        aws_sns_topic) as t
    group by
      subscription_status
    order by
      subscription_status desc;
  EOQ
}

query "sns_topic_monthly_forecast_table" {
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
        service = 'Amazon Simple Notification Service'
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

query "sns_topic_cost_per_month" {
  sql = <<-EOQ
    select
       to_char(period_start, 'Mon-YY') as "Month",
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Simple Notification Service'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "sns_topic_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(i.*) as "total"
    from
      aws_sns_topic as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      a.title
    order by
    count(i.*) desc;
  EOQ
}

query "sns_topic_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_sns_topic as i
    group by
      region;
  EOQ
}
