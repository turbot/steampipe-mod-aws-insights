query "aws_rds_db_instance_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "RDS DB Instance Snapshots" from aws_rds_db_snapshot
  EOQ
}

query "aws_rds_unencrypted_db_instance_snapshot_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted Instance Snapshots' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_snapshot
    where
      not encrypted
  EOQ
}

query "aws_rds_db_instance_snapshot_not_in_vpc_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Instance Snapshots not in VPC' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_snapshot
    where
      vpc_id is null
  EOQ
}

query "aws_rds_db_instance_snapshot_cost_per_month" {
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
      period_start
  EOQ
}

query "aws_rds_db_instance_snapshot_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_rds_db_snapshot as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc

  EOQ
}


query "aws_rds_db_instance_snapshot_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_rds_db_snapshot as i
    group by
      region
  EOQ
}


query "aws_rds_db_instance_snapshot_by_engine_type" {
  sql = <<-EOQ
    select engine as "Engine Type", count(*) as "Instance Snapshots" from aws_rds_db_snapshot group by engine order by engine
  EOQ
}

query "aws_rds_db_instance_snapshot_iam_authentication_enabled" {
  sql = <<-EOQ
    with iam_authentication_stat as (
    select
      distinct db_instance_identifier as name
    from
      aws_rds_db_snapshot
    where
      iam_database_authentication_enabled
    group by name
  )
  select
    'Enabled' as "IAM Authentication Status",
    count(name) as "Total"
  from
    iam_authentication_stat
  union
  select
    'Disabled' as "IAM Authentication Status",
    count( db_instance_identifier) as "Total"
  from
    aws_rds_db_snapshot as s where s.db_instance_identifier not in (select name from iam_authentication_stat)
  EOQ
}

query "aws_rds_db_instance_snapshot_by_encryption_status" {
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
        aws_rds_db_snapshot) as t
    group by
      encryption_status
    order by
      encryption_status desc
  EOQ
}

query "aws_rds_db_instance_snapshot_by_state" {
  sql = <<-EOQ
    select
      status,
      count(status)
    from
      aws_rds_db_snapshot
    group by
      status
  EOQ
}

query "aws_rds_db_instance_snapshot_by_creation_month" {
  sql = <<-EOQ
    with snapshots as (
      select
        title,
        create_time,
        to_char(create_time,
          'YYYY-MM') as creation_month
      from
        aws_rds_db_snapshot
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
      months.month desc
  EOQ
}

query "aws_rds_db_instance_snapshot_monthly_forecast_table" {
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
      (select average_daily_cost from monthly_costs where period_label = 'Month to Date') as "Daily Avg Cost"

  EOQ
}

dashboard "aws_rds_db_instance_snapshot_dashboard" {

  title = "AWS RDS DB Instance Snapshot Dashboard"

  container {

    card {
      sql   = query.aws_rds_db_instance_snapshot_count.sql
      width = 2
    }

    card {
      sql   = query.aws_rds_unencrypted_db_instance_snapshot_count.sql
      width = 2
    }

    card {
      sql   = query.aws_rds_db_instance_snapshot_not_in_vpc_count.sql
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
          service = 'Amazon Relational Database Service'
          and period_end > date_trunc('month', CURRENT_DATE::timestamp)
      EOQ
    }

  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      sql   = query.aws_rds_db_instance_snapshot_by_encryption_status.sql
      type  = "donut"
      width = 4
    }

    chart {
      title = "IAM Authentication Status"
      sql   = query.aws_rds_db_instance_snapshot_iam_authentication_enabled.sql
      type  = "donut"
      width = 4
    }

  }

  container {
    title = "Cost"
    width = 6

    # Costs
    table  {
      width = 6
      title = "Forecast"
      sql   = query.aws_rds_db_instance_snapshot_monthly_forecast_table.sql
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      sql   = query.aws_rds_db_instance_snapshot_cost_per_month.sql
    }
    
  }

  container {
    title = "Analysis"

    chart {
      title = "Snapshots by Account"
      sql   = query.aws_rds_db_instance_snapshot_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Snapshots by Region"
      sql   = query.aws_rds_db_instance_snapshot_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Snapshots by State"
      sql   = query.aws_rds_db_instance_snapshot_by_state.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Snapshots by Age"
      sql   = query.aws_rds_db_instance_snapshot_by_creation_month.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Snapshots by Type"
      sql   = query.aws_rds_db_instance_snapshot_by_engine_type.sql
      type  = "column"
      width = 3
    }

  }

}
