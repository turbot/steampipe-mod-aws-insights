query "aws_sqs_queue_count" {
  sql = <<-EOQ
    select count(*) as "Queues" from aws_sqs_queue;
  EOQ
}

query "aws_sqs_queue_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_sqs_queue
    where
      kms_master_key_id is null;
  EOQ
}

query "aws_sqs_queue_anonymous_access_count" {
    sql = <<-EOQ
      select
        count(*) as value,
        'Anonymous Access' as label,
        case count(*) when 0 then 'ok' else 'alert' end as "type"
      from
        aws_sqs_queue,
        jsonb_array_elements(policy_std -> 'Statement') as s,
        jsonb_array_elements_text(s -> 'Principal' -> 'AWS') as p,
        string_to_array(p, ':') as pa,
        jsonb_array_elements_text(s -> 'Action') as a
      where
        s ->> 'Effect' = 'Allow'
        and (
          pa[5] != account_id
          or p = '*'
        );
  EOQ
}

query "aws_sqs_queue_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_sqs_queue as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc;
  EOQ
}

query "aws_sqs_queue_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_sqs_queue as i
    group by
      region;
  EOQ
}

query "aws_sqs_queue_cost_per_month" {
  sql = <<-EOQ
    select
       to_char(period_start, 'Mon-YY') as "Month",
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Simple Queue Service'
    group by
      period_start
    order by
      period_start;
  EOQ
}

query "aws_sqs_queue_monthly_forecast_table" {
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
        service = 'Amazon Simple Queue Service'
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

query "aws_sqs_queue_by_encryption_status" {
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
        aws_sqs_queue) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "aws_sqs_queue_anonymous_access_status" {
  sql = <<-EOQ
    with anonymous_access as (
      select
      title
    from
      aws_sqs_queue,
      jsonb_array_elements(policy_std -> 'Statement') as s,
      jsonb_array_elements_text(s -> 'Principal' -> 'AWS') as p,
      string_to_array(p, ':') as pa,
      jsonb_array_elements_text(s -> 'Action') as a
    where
      s ->> 'Effect' = 'Allow'
      and (
        pa[5] != account_id
        or p = '*'
      )
    ), anonymous_access_status as(
      select
        case
          when a.title is null or policy_std is null then  'ok'
        else
          'alarm'
        end anonymous_access_status
      from
        aws_sqs_queue as q
        left join anonymous_access as a on q.title = a.title
      )
      select
        anonymous_access_status,
        count(*)
      from
        anonymous_access_status
      group by
        anonymous_access_status
      order by
        anonymous_access_status desc;
  EOQ
}

query "aws_sqs_queue_by_dlq_status" {
  sql = <<-EOQ
    select
      redrive_policy_status,
      count(*)
    from (
      select redrive_policy,
        case when redrive_policy is not null then
          'enabled'
        else
          'disabled'
        end redrive_policy_status
      from
        aws_sqs_queue) as t
    group by
      redrive_policy_status
    order by
      redrive_policy_status desc;
  EOQ
}


dashboard "aws_sqs_queue_dashboard" {

  title = "AWS SQS Queue Dashboard"

  tags = merge(local.sqs_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.aws_sqs_queue_count.sql
      width = 2
    }

    card {
      sql   = query.aws_sqs_queue_unencrypted_count.sql
      width = 2
    }

    card {
      sql   = query.aws_sqs_queue_anonymous_access_count.sql
      width = 2
    }

    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      sql   = <<-EOQ
        select
          'Cost - MTD' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_usage_type_monthly as c
        where
          service = 'Amazon Simple Queue Service'
          and period_end > date_trunc('month', CURRENT_DATE::timestamp);
      EOQ
    }

  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      sql = query.aws_sqs_queue_by_encryption_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "green"
        }
        point "disabled" {
          color = "red"
        }
      }
    }

    chart {
      title = "DLQ Status"
      sql = query.aws_sqs_queue_by_dlq_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "green"
        }
        point "disabled" {
          color = "red"
        }
      }
    }

    chart {
      title = "Anonymous Access Status"
      sql = query.aws_sqs_queue_anonymous_access_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "ok" {
          color = "green"
        }
        point "alarm" {
          color = "red"
        }
      }
    }

  }

container {
  title = "Cost"
  width = 6

  # Costs
  table  {
    width = 6
    title = "Forecast"
    sql   = query.aws_sqs_queue_monthly_forecast_table.sql
  }

  chart {
    width = 6
    type  = "column"
    title = "Monthly Cost - 12 Months"
    sql   = query.aws_sqs_queue_cost_per_month.sql
  }

}

container {
  title = "Analysis"

  chart {
    title = "Queues by Account"
    sql   = query.aws_sqs_queue_by_account.sql
    type  = "column"
    width = 3
  }
  chart {
    title = "Queues by Region"
    sql   = query.aws_sqs_queue_by_region.sql
    type  = "column"
    width = 3
  }

}

}
