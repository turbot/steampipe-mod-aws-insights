dashboard "aws_ebs_snapshot_dashboard" {

  title         = "AWS EBS Snapshot Dashboard"
  documentation = file("./dashboards/ebs/docs/ebs_snapshot_dashboard.md")

  tags = merge(local.ebs_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.aws_ebs_snapshot_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ebs_snapshot_storage_total.sql
      width = 2
    }

    card {
      sql   = query.aws_ebs_unencrypted_snapshot_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ebs_snapshot_public_count.sql
      width = 2
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      sql   = query.aws_ebs_snapshot_cost_mtd.sql
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      sql   = query.aws_ebs_snapshot_by_encryption_status.sql
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
      title = "Public/Private"
      sql   = query.aws_ebs_snapshot_by_public_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "private" {
          color = "ok"
        }
        point "public" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Cost"
    width = 6

    # Costs
    table {
      width = 6
      title = "Forecast"
      sql   = query.aws_ebs_snapshot_monthly_forecast_table.sql
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      sql   = query.aws_ebs_snapshot_cost_per_month.sql
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Snapshots by Account"
      sql   = query.aws_ebs_snapshot_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Snapshots by Region"
      sql   = query.aws_ebs_snapshot_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Snapshots by Age"
      sql   = query.aws_ebs_snapshot_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

  container {

    chart {
      title = "Storage by Account (GB)"
      sql   = query.aws_ebs_snapshot_storage_by_account.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Region (GB)"
      sql   = query.aws_ebs_snapshot_storage_by_region.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Age (GB)"
      sql   = query.aws_ebs_snapshot_storage_by_age.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }


  }
}

# Card Queries

query "aws_ebs_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "Snapshots" from aws_ebs_snapshot;
  EOQ
}

query "aws_ebs_snapshot_storage_total" {
  sql = <<-EOQ
    select
      sum(volume_size) as "Total Storage (GB)"
    from
      aws_ebs_snapshot;
  EOQ
}

query "aws_ebs_unencrypted_snapshot_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
       aws_ebs_snapshot
    where
       not encrypted;
  EOQ
}

query "aws_ebs_snapshot_public_count" {
  sql = <<-EOQ
      select
        count(*) as value,
        'Publicly Accessible' as label,
        case count(*) when 0 then 'ok' else 'alert' end as type
      from
        aws_ebs_snapshot
      where
        create_volume_permissions @> '[{"Group": "all"}]';
  EOQ
}

query "aws_ebs_snapshot_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_usage_type_monthly as c
    where
      service = 'EC2 - Other'
      and usage_type like '%EBS:Snapshot%'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp);
  EOQ
}

# Assessment Queries

query "aws_ebs_snapshot_by_encryption_status" {
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
        aws_ebs_snapshot) as t
    group by
      encryption_status
    order by
      encryption_status;
  EOQ
}

query "aws_ebs_snapshot_by_public_status" {
  sql = <<-EOQ
    with public_status as (
      select
        case when create_volume_permissions @> '[{"Group": "all"}]' then
          'public'
        else
          'private'
        end as visibility
      from aws_ebs_snapshot
    )
    select
      visibility,
      count(*)
    from
      public_status
    group by
      visibility;
  EOQ
}

# Cost Queries

query "aws_ebs_snapshot_monthly_forecast_table" {
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
        and usage_type like '%EBS:Snapshot%'
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

query "aws_ebs_snapshot_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'EC2 - Other'
      and usage_type like '%EBS:Snapshot%'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "aws_ebs_snapshot_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(s.*) as "Snapshots"
    from
      aws_ebs_snapshot as s,
      aws_account as a
    where
      a.account_id = s.account_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "aws_ebs_snapshot_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Snapshots" from aws_ebs_snapshot group by region order by region
  EOQ
}

query "aws_ebs_snapshot_by_creation_month" {
  sql = <<-EOQ
    with snapshots as (
      select
        title,
        start_time,
        to_char(start_time,
          'YYYY-MM') as creation_month
      from
        aws_ebs_snapshot
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(start_time)
                from snapshots)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    snapshots_by_month as (
      select
        creation_month,
        count(*)
      from
        snapshots
      group by
        creation_month
    )
    select
      months.month,
      snapshots_by_month.count
    from
      months
      left join snapshots_by_month on months.month = snapshots_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "aws_ebs_snapshot_storage_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      sum(s.volume_size) as "GB"
    from
      aws_ebs_snapshot as s,
      aws_account as a
    where
      a.account_id = s.account_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "aws_ebs_snapshot_storage_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      sum(volume_size) as "GB"
    from
      aws_ebs_snapshot
    group by
      region
    order by
      region;
  EOQ
}

query "aws_ebs_snapshot_storage_by_age" {
  sql = <<-EOQ
    with snapshots as (
      select
        title,
        volume_size,
        start_time,
        to_char(start_time,
          'YYYY-MM') as creation_month
      from
        aws_ebs_snapshot
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(start_time)
                from snapshots)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    snapshots_by_month as (
      select
        creation_month,
        sum(volume_size) as size
      from
        snapshots
      group by
        creation_month
    )
    select
      months.month,
      snapshots_by_month.size as "GB"
    from
      months
      left join snapshots_by_month on months.month = snapshots_by_month.creation_month
    order by
      months.month;
  EOQ
}
