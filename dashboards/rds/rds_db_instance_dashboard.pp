dashboard "rds_db_instance_dashboard" {

  title         = "AWS RDS DB Instance Dashboard"
  documentation = file("./dashboards/rds/docs/rds_db_instance_dashboard.md")

  tags = merge(local.rds_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.rds_db_instance_count
      width = 2
    }

    # Assessments
    card {
      query = query.rds_db_instance_public_count
      width = 2
      href  = dashboard.rds_db_instance_public_access_report.url_path
    }

    card {
      query = query.rds_db_instance_unencrypted_count
      width = 2
      href  = dashboard.rds_db_instance_encryption_report.url_path
    }

    card {
      query = query.rds_db_instance_logging_disabled_count
      width = 2
      href  = dashboard.rds_db_instance_logging_report.url_path
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      query = query.rds_db_instance_cost_mtd
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Public/Private Status"
      query = query.rds_db_instance_public_status
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

    chart {
      title = "Encryption Status"
      query = query.rds_db_instance_by_encryption_status
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
      query = query.rds_db_instance_logging_status
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
      query = query.rds_db_instance_multiple_az_status
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
      query = query.rds_db_instance_deletion_protection_status
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
      query = query.rds_db_instance_monthly_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.rds_db_instance_cost_per_month
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Instances by Account"
      query = query.rds_db_instance_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Region"
      query = query.rds_db_instance_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by State"
      query = query.rds_db_instance_by_state
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Age"
      query = query.rds_db_instance_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Engine Type"
      query = query.rds_db_instance_by_engine_type
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Class"
      query = query.rds_db_instance_by_class
      type  = "column"
      width = 4
    }

  }

  container {

    title = "Performance & Utilization"
    width = 12

    chart {
      title = "Top 10 CPU - Last 7 days"
      query = query.rds_db_instance_top10_cpu_past_week
      type  = "line"
      width = 6
    }

    chart {
      title = "Average max daily CPU - Last 30 days"
      query = query.rds_db_instance_by_cpu_utilization_category
      type  = "column"
      width = 6
    }

  }

}

# Card Queries

query "rds_db_instance_count" {
  sql = <<-EOQ
    select count(*) as "RDS DB Instances" from aws_rds_db_instance
  EOQ
}

query "rds_db_instance_public_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Publicly Accessible' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_instance
    where
      publicly_accessible;
  EOQ
}

query "rds_db_instance_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_instance
    where
      not storage_encrypted;
  EOQ
}

query "rds_db_instance_logging_disabled_count" {
  sql = <<-EOQ
    with logging_stat as (
      select
        db_instance_identifier
      from
        aws_rds_db_instance
      where
        ( engine like any (array ['mariadb', '%mysql']) and enabled_cloudwatch_logs_exports ?& array ['audit','error','general','slowquery'] ) or
        ( engine like any (array['%postgres%']) and enabled_cloudwatch_logs_exports ?& array ['postgresql','upgrade'] ) or
        ( engine like 'oracle%' and enabled_cloudwatch_logs_exports ?& array ['alert','audit', 'trace','listener'] ) or
        ( engine = 'sqlserver-ex' and enabled_cloudwatch_logs_exports ?& array ['error'] ) or
        ( engine like 'sqlserver%' and enabled_cloudwatch_logs_exports ?& array ['error','agent'] )
    )
    select
      count(*) as value,
      'Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_instance
    where
      db_instance_identifier not in (select db_instance_identifier from logging_stat);
  EOQ
}

query "rds_db_instance_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Relational Database Service'
      and usage_type like '%Instance%'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp);
  EOQ
}

# Assessment Queries

query "rds_db_instance_public_status" {
  sql = <<-EOQ
    with db_instances as (
      select
        case
          when publicly_accessible is null or (not publicly_accessible) then 'private'
          else 'public'
        end as visibility
      from
        aws_rds_db_instance
    )
    select
      visibility,
      count(*)
    from
      db_instances
    group by
      visibility;
  EOQ
}

query "rds_db_instance_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select
        case when storage_encrypted then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_rds_db_instance) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "rds_db_instance_logging_status" {
  sql = <<-EOQ
    with logging_enabled as (
      select
        db_instance_identifier as name
      from
        aws_rds_db_instance
      where
        (engine like any (array ['mariadb', '%mysql']) and enabled_cloudwatch_logs_exports ?& array ['audit','error','general','slowquery'] )or
        ( engine like any (array['%postgres%']) and enabled_cloudwatch_logs_exports ?& array ['postgresql','upgrade'] ) or
        ( engine like 'oracle%' and enabled_cloudwatch_logs_exports ?& array ['alert','audit', 'trace','listener'] ) or
        ( engine = 'sqlserver-ex' and enabled_cloudwatch_logs_exports ?& array ['error'] ) or
        ( engine like 'sqlserver%' and enabled_cloudwatch_logs_exports ?& array ['error','agent'] )
    ),
    logging_status as (
      select
        case
          when l.name is not null  then 'enabled'
          else 'disabled' end as db_instance_logging_status
      from
        aws_rds_db_instance as i
        left join logging_enabled as l on i.db_instance_identifier = l.name
    )
    select
      db_instance_logging_status,
      count(*)
    from
      logging_status
    group by
      db_instance_logging_status;
  EOQ
}

query "rds_db_instance_multiple_az_status" {
  sql = <<-EOQ
    with db_instances as (
      select
        case
          when multi_az then 'enabled'
          else 'disabled'
        end as visibility
      from
        aws_rds_db_instance
      where
        engine not ilike any (array ['%aurora-mysql%', '%aurora-postgres%'])
    )
    select
      visibility,
      count(*)
    from
      db_instances
    group by
      visibility;
  EOQ
}

query "rds_db_instance_deletion_protection_status" {
  sql = <<-EOQ
    with db_instances as (
      select
        case
          when deletion_protection then 'enabled'
          else 'disabled'
        end as visibility
      from
        aws_rds_db_instance
    )
    select
      visibility,
      count(*)
    from
      db_instances
    group by
      visibility;
  EOQ
}

# Cost Queries

query "rds_db_instance_monthly_forecast_table" {
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
        and usage_type like '%Instance%'
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

query "rds_db_instance_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount)::numeric as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Relational Database Service'
      and usage_type like '%Instance%'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "rds_db_instance_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(i.*) as "total"
    from
      aws_rds_db_instance as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      a.title
    order by 
      count(i.*) desc;
  EOQ
}

query "rds_db_instance_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_rds_db_instance as i
    group by
      region;
  EOQ
}

query "rds_db_instance_by_state" {
  sql = <<-EOQ
    select
      status,
      count(status)
    from
      aws_rds_db_instance
    group by
      status;
  EOQ
}

query "rds_db_instance_by_creation_month" {
  sql = <<-EOQ
    with instances as (
      select
        title,
        create_time,
        to_char(create_time,
          'YYYY-MM') as creation_month
      from
        aws_rds_db_instance
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
                from instances)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    instances_by_month as (
      select
        creation_month,
        count(*)
      from
        instances
      group by
        creation_month
    )
    select
      months.month,
      instances_by_month.count
    from
      months
      left join instances_by_month on months.month = instances_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "rds_db_instance_by_engine_type" {
  sql = <<-EOQ
    select engine as "Engine Type", count(*) as "instances" from aws_rds_db_instance group by engine order by engine;
  EOQ
}

query "rds_db_instance_by_class" {
  sql = <<-EOQ
    select
      class,
      count(class)
    from
      aws_rds_db_instance
    group by
      class;
  EOQ
}

# Performance Queries

query "rds_db_instance_top10_cpu_past_week" {
  sql = <<-EOQ
    with top_n as (
      select
        db_instance_identifier,
        avg(average)
      from
        aws_rds_db_instance_metric_cpu_utilization_daily
      where
        timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      group by
        db_instance_identifier
      order by
        avg desc
      limit 10
  )
  select
      timestamp,
      db_instance_identifier,
      average
    from
       aws_rds_db_instance_metric_cpu_utilization_hourly
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and db_instance_identifier in (select db_instance_identifier from top_n)
    order by
      timestamp;
  EOQ
}

query "rds_db_instance_by_cpu_utilization_category" {
  sql = <<-EOQ
    with cpu_buckets as (
      select
    unnest(array ['Unused (<1%)','Underutilized (1-10%)','Right-sized (10-90%)', 'Overutilized (>90%)' ]) as cpu_bucket
    ),
    max_averages as (
      select
        db_instance_identifier,
        case
          when max(average) <= 1 then 'Unused (<1%)'
          when max(average) between 1 and 10 then 'Underutilized (1-10%)'
          when max(average) between 10 and 90 then 'Right-sized (10-90%)'
          when max(average) > 90 then 'Overutilized (>90%)'
        end as cpu_bucket,
        max(average) as max_avg
      from
        aws_rds_db_instance_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        db_instance_identifier
    )
    select
      b.cpu_bucket as "CPU Utilization",
      count(a.*)
    from
      cpu_buckets as b
    left join max_averages as a on b.cpu_bucket = a.cpu_bucket
    group by
      b.cpu_bucket;
  EOQ
}
