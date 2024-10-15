dashboard "ec2_instance_dashboard" {

  title         = "AWS EC2 Instance Dashboard"
  documentation = file("./dashboards/ec2/docs/ec2_instance_dashboard.md")

  tags = merge(local.ec2_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.ec2_instance_count
      width = 2
    }

    card {
      query = query.ec2_instance_total_cores
      width = 2
    }

    # Assessments
    card {
      query = query.ec2_public_instance_count
      width = 2
      href  = dashboard.ec2_instance_public_access_report.url_path
    }

    card {
      query = query.ec2_ebs_optimized_count
      width = 2
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      query = query.ec2_instance_cost_mtd
      width = 2
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Public/Private"
      query = query.ec2_instance_by_public_ip
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
      title = "EBS Optimized Status"
      query = query.ec2_instance_ebs_optimized_status
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
      title = "Detailed Monitoring Status"
      query = query.ec2_instance_detailed_monitoring_enabled
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

    title = "Costs"
    width = 6


    table {
      width = 6
      title = "Forecast"
      query = query.ec2_monthly_forecast_table
    }

    chart {
      width = 6
      title = "EC2 Compute Monthly Unblended Cost"
      type  = "column"
      query = query.ec2_instance_cost_per_month
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Instances by Account"
      query = query.ec2_instance_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Region"
      query = query.ec2_instance_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by State"
      query = query.ec2_instance_by_state
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Age"
      query = query.ec2_instance_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Type"
      query = query.ec2_instance_by_type
      type  = "column"
      width = 4
    }

  }

  container {

    title = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days"
      query = query.ec2_top10_cpu_past_week
      type  = "line"
      width = 6
    }

    chart {
      title = "Average Max Daily CPU - Last 30 days"
      query = query.ec2_instance_by_cpu_utilization_category
      type  = "column"
      width = 6
    }

  }

}

# Card Queries

query "ec2_instance_count" {
  sql = <<-EOQ
    select count(*) as "Instances" from aws_ec2_instance
  EOQ
}

query "ec2_instance_total_cores" {
  sql = <<-EOQ
    select
      sum(cpu_options_core_count) as "Total Cores"
    from
      aws_ec2_instance as i
  EOQ
}

query "ec2_public_instance_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Publicly Accessible' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ec2_instance
    where
      public_ip_address is not null
  EOQ
}

query "ec2_ebs_optimized_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'EBS Not Optimized' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ec2_instance
    where
      not ebs_optimized
  EOQ
}

query "ec2_instance_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_monthly
    where
      service = 'Amazon Elastic Compute Cloud - Compute'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
  EOQ
}

# Assessment Queries

query "ec2_instance_by_public_ip" {
  sql = <<-EOQ
    with instances as (
      select
        case
          when public_ip_address is null then 'private'
          else 'public'
        end as visibility
      from
        aws_ec2_instance
    )
    select
      visibility,
      count(*)
    from
      instances
    group by
      visibility
  EOQ
}

query "ec2_instance_ebs_optimized_status" {
  sql = <<-EOQ
    with instances as (
      select
        case
          when ebs_optimized then 'enabled'
          else 'disabled'
        end as visibility
      from
        aws_ec2_instance
    )
    select
      visibility,
      count(*)
    from
      instances
    group by
      visibility
  EOQ
}

query "ec2_instance_detailed_monitoring_enabled" {
  sql = <<-EOQ
    with instances as (
      select
        case
          when monitoring_state = 'enabled' then 'enabled'
          else 'disabled'
        end as visibility
      from
        aws_ec2_instance
    )
    select
      visibility,
      count(*)
    from
      instances
    group by
      visibility
  EOQ
}

# Cost Queries

query "ec2_monthly_forecast_table" {
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
        service = 'Amazon Elastic Compute Cloud - Compute'
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

query "ec2_instance_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount)::numeric as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Elastic Compute Cloud - Compute'
    group by
      period_start
    order by
      period_start
  EOQ
}

# Analysis Queries

query "ec2_instance_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(i.*) as "total"
    from
      aws_ec2_instance as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      a.title
    order by 
      count(i.*) desc;
  EOQ
}

query "ec2_instance_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_ec2_instance as i
    group by
      region
  EOQ
}

query "ec2_instance_by_state" {
  sql = <<-EOQ
    select
      instance_state,
      count(instance_state)
    from
      aws_ec2_instance
    group by
      instance_state
  EOQ
}

query "ec2_instance_by_creation_month" {
  sql = <<-EOQ
    with instances as (
      select
        title,
        launch_time,
        to_char(launch_time,
          'YYYY-MM') as creation_month
      from
        aws_ec2_instance
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(launch_time)
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

query "ec2_instance_by_type" {
  sql = <<-EOQ
    select instance_type as "Type", count(*) as "instances" from aws_ec2_instance group by instance_type order by instance_type
  EOQ
}

# Note the CTE uses the dailt table to be efficient when filtering,
# and the hourly table to show granular line chart

# Performance Queries

query "ec2_top10_cpu_past_week" {
  sql = <<-EOQ
    with top_n as (
    select
      instance_id,
      avg(average)
    from
      aws_ec2_instance_metric_cpu_utilization_daily
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
    group by
      instance_id
    order by
      avg desc
    limit 10
  )
  select
      timestamp,
      instance_id,
      average
    from
      aws_ec2_instance_metric_cpu_utilization_hourly
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and instance_id in (select instance_id from top_n)
    order by
      timestamp;
  EOQ
}

# underused if avg CPU < 10% every day for last month
query "ec2_instance_by_cpu_utilization_category" {
  sql = <<-EOQ
    with cpu_buckets as (
      select
    unnest(array ['Unused (<1%)','Underutilized (1-10%)','Right-sized (10-90%)', 'Overutilized (>90%)' ]) as cpu_bucket
    ),
    max_averages as (
      select
        instance_id,
        case
          when max(average) <= 1 then 'Unused (<1%)'
          when max(average) between 1 and 10 then 'Underutilized (1-10%)'
          when max(average) between 10 and 90 then 'Right-sized (10-90%)'
          when max(average) > 90 then 'Overutilized (>90%)'
        end as cpu_bucket,
        max(average) as max_avg
      from
        aws_ec2_instance_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        instance_id
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
