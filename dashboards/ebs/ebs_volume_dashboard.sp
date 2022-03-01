dashboard "aws_ebs_volume_dashboard" {

  title = "AWS EBS Volume Dashboard"

  tags = merge(local.ebs_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.aws_ebs_volume_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ebs_volume_storage_total.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_ebs_volume_unencrypted_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ebs_volume_unattached_count.sql
      width = 2
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      sql   = query.aws_ebs_volume_cost_mtd.sql
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      sql   = query.aws_ebs_volume_by_encryption_status.sql
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
      title = "Volume State"
      sql   = query.aws_ebs_volume_by_state.sql
      type  = "donut"
      width = 4

      series "count" {
        point "in-use" {
          color = "green"
        }
        point "available" {
          color = "red"
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
      sql   = query.aws_ebs_volume_monthly_forecast_table.sql
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      sql   = query.aws_ebs_volume_cost_per_month.sql
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Volumes by Account"
      sql   = query.aws_ebs_volume_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volumes by Region"
      sql   = query.aws_ebs_volume_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volumes by Type"
      sql   = query.aws_ebs_volume_by_type.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volumes by Age"
      sql   = query.aws_ebs_volume_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

  container {

    chart {
      title = "Storage by Account (GB)"
      sql   = query.aws_ebs_volume_storage_by_account.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Region (GB)"
      sql   = query.aws_ebs_volume_storage_by_region.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Type (GB)"
      sql   = query.aws_ebs_volume_storage_by_type.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Age (GB)"
      sql   = query.aws_ebs_volume_storage_by_creation_month.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

  }

  container {

    title = "Performance & Utilization"

    chart {
      title = "Top 10 Average Read IOPS - Last 7 days"
      type  = "line"
      width = 6
      sql   = query.aws_ebs_volume_top_10_read_ops_avg.sql
    }

    chart {
      title = "Top 10 Average Write IOPS - Last 7 days"
      type  = "line"
      width = 6
      sql   = query.aws_ebs_volume_top_10_write_ops_avg.sql
    }

  }

}

# Card Queries

query "aws_ebs_volume_count" {
  sql = <<-EOQ
    select
      count(*) as "Volumes"
    from
      aws_ebs_volume;
  EOQ
}

query "aws_ebs_volume_storage_total" {
  sql = <<-EOQ
    select
      sum(size) as "Total Storage (GB)"
    from
      aws_ebs_volume;
  EOQ
}

query "aws_ebs_volume_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ebs_volume
    where
      not encrypted;
  EOQ
}

query "aws_ebs_volume_unattached_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unattached' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ebs_volume
    where
      attachments is null;
  EOQ
}

query "aws_ebs_volume_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_usage_type_monthly as c
    where
      service = 'EC2 - Other'
      and usage_type like '%EBS:%'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp);
  EOQ
}

# Assessment Queries

query "aws_ebs_volume_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select encrypted,
        case when encrypted then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_ebs_volume) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "aws_ebs_volume_by_state" {
  sql = <<-EOQ
    select
      state,
      count(state)
    from
      aws_ebs_volume
    group by
      state;
  EOQ
}

# Cost Queries

query "aws_ebs_volume_monthly_forecast_table" {
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
        service = 'EC2 - Other'
        and usage_type like '%EBS:%'
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

query "aws_ebs_volume_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'EC2 - Other'
      and usage_type like '%EBS:%'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "aws_ebs_volume_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(v.*) as "volumes"
    from
      aws_ebs_volume as v,
      aws_account as a
    where
      a.account_id = v.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "aws_ebs_volume_storage_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      sum(v.size) as "GB"
    from
      aws_ebs_volume as v,
      aws_account as a
    where
      a.account_id = v.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "aws_ebs_volume_by_type" {
  sql = <<-EOQ
    select
      volume_type as "Type",
      count(*) as "volumes"
    from
      aws_ebs_volume
    group by
      volume_type
    order by
      volume_type;
  EOQ
}

query "aws_ebs_volume_storage_by_type" {
  sql = <<-EOQ
    select
      volume_type,
      sum(size) as "GB"
    from
      aws_ebs_volume
    group by
      volume_type
    order by
      volume_type;
  EOQ
}

query "aws_ebs_volume_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "volumes"
    from
      aws_ebs_volume
    group by
      region
    order by
      region;
  EOQ
}

query "aws_ebs_volume_storage_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      sum(size) as "GB"
    from
      aws_ebs_volume
    group by
      region
    order by
      region;
  EOQ
}

query "aws_ebs_volume_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        create_time,
        to_char(create_time,
          'YYYY-MM') as creation_month
      from
        aws_ebs_volume
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(create_time)
                from volumes)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    volumes_by_month as (
      select
        creation_month,
        count(*)
      from
        volumes
      group by
        creation_month
    )
    select
      months.month,
      volumes_by_month.count
    from
      months
      left join volumes_by_month on months.month = volumes_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "aws_ebs_volume_storage_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        size,
        create_time,
        to_char(create_time,
          'YYYY-MM') as creation_month
      from
        aws_ebs_volume
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(create_time)
                from volumes)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    volumes_by_month as (
      select
        creation_month,
        sum(size) as size
      from
        volumes
      group by
        creation_month
    )
    select
      months.month,
      volumes_by_month.size as "GB"
    from
      months
      left join volumes_by_month on months.month = volumes_by_month.creation_month
    order by
      months.month;
  EOQ
}

# Performance Queries

query "aws_ebs_volume_top_10_read_ops_avg" {
  sql = <<-EOQ
    with top_n as (
      select
        volume_id,
        avg(average)
      from
        aws_ebs_volume_metric_read_ops_daily
      where
        timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      group by
        volume_id
      order by
        avg desc
      limit 10
    )
    select
        timestamp,
        volume_id,
        average
      from
        aws_ebs_volume_metric_read_ops_hourly
      where
        timestamp  >= CURRENT_DATE - INTERVAL '7 day'
        and volume_id in (select volume_id from top_n);
  EOQ
}

query "aws_ebs_volume_top_10_write_ops_avg" {
  sql = <<-EOQ
    with top_n as (
      select
        volume_id,
        avg(average)
      from
        aws_ebs_volume_metric_write_ops_daily
      where
        timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      group by
        volume_id
      order by
        avg desc
      limit 10
    )
    select
      timestamp,
      volume_id,
      average
    from
      aws_ebs_volume_metric_write_ops_hourly
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and volume_id in (select volume_id from top_n);
  EOQ
}
