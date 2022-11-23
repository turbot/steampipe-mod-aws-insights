dashboard "aws_rds_db_cluster_snapshot_dashboard" {

  title         = "AWS RDS DB Cluster Snapshot Dashboard"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_snapshot_dashboard.md")

  tags = merge(local.rds_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.aws_rds_db_cluster_snapshot_count
      width = 2
    }

    # Assessments
    card {
      query = query.aws_rds_db_cluster_snapshot_unencrypted_count
      width = 2
      href  = dashboard.aws_rds_db_cluster_snapshot_encryption_report.url_path
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      query = query.aws_rds_db_cluster_snapshot_cost_mtd
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      query = query.aws_rds_db_cluster_snapshot_by_encryption_status
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
      title = "IAM Authentication Status"
      query = query.aws_rds_db_cluster_snapshot_iam_authentication_enabled
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
      query = query.aws_rds_db_cluster_snapshot_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.aws_rds_db_cluster_snapshot_cost_per_month
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Snapshots by Account"
      query = query.aws_rds_db_cluster_snapshot_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by Region"
      query = query.aws_rds_db_cluster_snapshot_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by State"
      query = query.aws_rds_db_cluster_snapshot_by_state
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by Age"
      query = query.aws_rds_db_cluster_snapshot_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by Engine Type"
      query = query.aws_rds_db_cluster_snapshot_by_engine_type
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "aws_rds_db_cluster_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "Cluster Snapshots" from aws_rds_db_cluster_snapshot;
  EOQ
}

query "aws_rds_db_cluster_snapshot_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster_snapshot
    where
      not storage_encrypted;
  EOQ
}

query "aws_rds_db_cluster_snapshot_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_usage_type_monthly as c
    where
      service = 'Amazon Relational Database Service'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp);
  EOQ
}

# Assessment Queries

query "aws_rds_db_cluster_snapshot_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select storage_encrypted,
        case when storage_encrypted then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_rds_db_cluster_snapshot) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "aws_rds_db_cluster_snapshot_iam_authentication_enabled" {
  sql = <<-EOQ
    with iam_authentication_enabled as (
      select
        distinct db_cluster_identifier as name
      from
        aws_rds_db_cluster_snapshot
      where
        iam_database_authentication_enabled
      group by name
    ),
    iam_authentication_status as (
      select
        case
          when e.name is not null  then 'enabled'
          else 'disabled' end as iam_authentication_status
      from
        aws_rds_db_cluster_snapshot as c
        left join iam_authentication_enabled as e on c.db_cluster_identifier = e.name
    )
    select
      iam_authentication_status,
      count(*)
    from
      iam_authentication_status
    group by
      iam_authentication_status;
  EOQ
}

# Cost Queries

query "aws_rds_db_cluster_snapshot_forecast_table" {
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
        service = 'Amazon Relational Database Service'
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

query "aws_rds_db_cluster_snapshot_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Relational Database Service'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "aws_rds_db_cluster_snapshot_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_rds_db_cluster_snapshot as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc;
  EOQ
}

query "aws_rds_db_cluster_snapshot_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_rds_db_cluster_snapshot as i
    group by
      region;
  EOQ
}

query "aws_rds_db_cluster_snapshot_by_state" {
  sql = <<-EOQ
    select
      status,
      count(status)
    from
      aws_rds_db_cluster_snapshot
    group by
      status;
  EOQ
}

query "aws_rds_db_cluster_snapshot_by_creation_month" {
  sql = <<-EOQ
    with snapshots as (
      select
        title,
        create_time,
        to_char(create_time,
          'YYYY-MM') as creation_month
      from
        aws_rds_db_cluster_snapshot
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

query "aws_rds_db_cluster_snapshot_by_engine_type" {
  sql = <<-EOQ
    select engine as "Engine Type", count(*) as "Cluster Snapshots" from aws_rds_db_cluster_snapshot group by engine order by engine;
  EOQ
}
