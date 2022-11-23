dashboard "aws_rds_db_cluster_dashboard" {

  title         = "AWS RDS DB Cluster Dashboard"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_dashboard.md")

  tags = merge(local.rds_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.aws_rds_db_cluster_count
      width = 2
    }

    # Assessments
    card {
      query = query.aws_rds_db_cluster_unencrypted_count
      width = 2
      href  = dashboard.aws_rds_db_cluster_encryption_report.url_path
    }

    card {
      query = query.aws_rds_db_cluster_logging_disabled_count
      width = 2
      href  = dashboard.aws_rds_db_cluster_logging_report.url_path
    }

    card {
      query = query.aws_rds_db_cluster_no_deletion_protection_count
      width = 2
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      query = query.aws_rds_db_cluster_cost_mtd
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      query = query.aws_rds_db_cluster_by_encryption_status
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
      title = "Logging Status"
      query = query.aws_rds_db_cluster_logging_status
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
      title = "Deletion Protection Status"
      query = query.aws_rds_db_cluster_deletion_protection_status
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
      title = "Multi-AZ Status"
      query = query.aws_rds_db_cluster_multiple_az_status
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
      query = query.aws_rds_db_cluster_monthly_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.aws_rds_db_cluster_cost_per_month
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Clusters by Account"
      query = query.aws_rds_db_cluster_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Region"
      query = query.aws_rds_db_cluster_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by State"
      query = query.aws_rds_db_cluster_by_state
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Age"
      query = query.aws_rds_db_cluster_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Type"
      query = query.aws_rds_db_cluster_by_engine_type
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "aws_rds_db_cluster_count" {
  sql = <<-EOQ
    select count(*) as "DB Clusters" from aws_rds_db_cluster;
  EOQ
}

query "aws_rds_db_cluster_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      not storage_encrypted;
  EOQ
}

query "aws_rds_db_cluster_logging_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      enabled_cloudwatch_logs_exports is null;
  EOQ
}

query "aws_rds_db_cluster_no_deletion_protection_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Deletion Protection Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      not deletion_protection;
  EOQ
}

query "aws_rds_db_cluster_cost_mtd" {
  sql = <<-EOQ
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

# Assessment Queries

query "aws_rds_db_cluster_by_encryption_status" {
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
        aws_rds_db_cluster) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "aws_rds_db_cluster_logging_status" {
  sql = <<-EOQ
    select
      logging_status,
      count(*)
    from (
      select
        case when  (engine like any (array ['mariadb', '%mysql']) and enabled_cloudwatch_logs_exports ?& array ['audit','error','general','slowquery'] )or
        ( engine like any (array['%postgres%']) and enabled_cloudwatch_logs_exports ?& array ['postgresql','upgrade'] ) or
        ( engine like 'oracle%' and enabled_cloudwatch_logs_exports ?& array ['alert','audit', 'trace','listener'] ) or
        ( engine = 'sqlserver-ex' and enabled_cloudwatch_logs_exports ?& array ['error'] ) or
        ( engine like 'sqlserver%' and enabled_cloudwatch_logs_exports ?& array ['error','agent'] )
      then 'enabled'
        else
          'disabled'
        end logging_status
      from
        aws_rds_db_cluster) as t
    group by
      logging_status
    order by
      logging_status desc;
  EOQ
}

query "aws_rds_db_cluster_deletion_protection_status" {
  sql = <<-EOQ
    select
      deletion_protection_status,
      count(*)
    from (
      select
        case when deletion_protection then
          'enabled'
        else
          'disabled'
        end deletion_protection_status
      from
        aws_rds_db_cluster) as t
    group by
      deletion_protection_status
    order by
      deletion_protection_status desc;
  EOQ
}

query "aws_rds_db_cluster_multiple_az_status" {
  sql = <<-EOQ
    with multiaz_enabled as (
      select
        distinct db_cluster_identifier as name
      from
        aws_rds_db_cluster
      where
        multi_az
      group by name
    ),
    multiaz_status as (
      select
        case
          when c.name is not null  then 'enabled'
          else 'disabled' end as multiaz_stat
      from
        aws_rds_db_cluster as r
        left join multiaz_enabled as c on r.db_cluster_identifier = c.name
    )
    select
      multiaz_stat,
      count(*)
    from
      multiaz_status
    group by
      multiaz_stat;
  EOQ
}

# Cost Queries

query "aws_rds_db_cluster_monthly_forecast_table" {
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

query "aws_rds_db_cluster_cost_per_month" {
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

query "aws_rds_db_cluster_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_rds_db_cluster as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc;
  EOQ
}

query "aws_rds_db_cluster_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_rds_db_cluster as i
    group by
      region;
  EOQ
}

query "aws_rds_db_cluster_by_state" {
  sql = <<-EOQ
    select
      status,
      count(status)
    from
      aws_rds_db_cluster
    group by
      status;
  EOQ
}

query "aws_rds_db_cluster_by_creation_month" {
  sql = <<-EOQ
    with clusters as (
      select
        title,
        create_time,
        to_char(create_time,
          'YYYY-MM') as creation_month
      from
        aws_rds_db_cluster
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
                from clusters)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    clusters_by_month as (
      select
        creation_month,
        count(*)
      from
        clusters
      group by
        creation_month
    )
    select
      months.month,
      clusters_by_month.count
    from
      months
      left join clusters_by_month on months.month = clusters_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "aws_rds_db_cluster_by_engine_type" {
  sql = <<-EOQ
    select engine as "Engine Type", count(*) as "Clusters" from aws_rds_db_cluster group by engine order by engine;
  EOQ
}
