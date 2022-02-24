query "aws_ec2_instance_count" {
  sql = <<-EOQ
    select count(*) as "Instances" from aws_ec2_instance
  EOQ
}

query "aws_ec2_instance_total_cores" {
  sql = <<-EOQ
    select
      sum(cpu_options_core_count) as "Total Cores"
    from
      aws_ec2_instance as i
  EOQ
}

query "aws_ec2_public_instance_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ec2_instance
    where
      public_ip_address is not null
  EOQ
}

query "aws_ec2_ebs_optimized_count" {
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

query "aws_ec2_root_volume_unencrypted_instance_count" {
  sql = <<-EOQ
    with encrypted_instances as (
      select
        encrypted,
        volume_id,
        att -> 'InstanceId' as "instanceid",
        att -> 'Device' as "device"
      from
        aws_ebs_volume,
        jsonb_array_elements(attachments) as att  where not encrypted
        and attachments is not null
    )
    select
      count(*) as value,
      'Root Volume Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ec2_instance as i left join encrypted_instances as e on ((e.instanceid)::text = i.instance_id) and (i.root_device_name = (e.device)::text)
  EOQ
}

# Assessments
query "aws_ec2_instance_by_public_ip" {
  sql = <<-EOQ
    with instances as (
      select
        case
          when public_ip_address is null then 'Private'
          else 'Public'
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

query "aws_ec2_instance_ebs_optimized_status" {
  sql = <<-EOQ
    with instances as (
      select
        case
          when ebs_optimized then 'Enabled'
          else 'Disabled'
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

query "aws_ec2_instance_root_volume_encryption_status" {
  sql = <<-EOQ
    with encrypted_instances as (
      select
        encrypted,
        volume_id,
        att -> 'InstanceId' as "instanceid",
        att -> 'Device' as "device"
      from
        aws_ebs_volume,
        jsonb_array_elements(attachments) as att
      where
        encrypted and attachments is not null
    )
    select
      encryption_status,
      count(*)
    from (
      select
        case when e.encrypted then
          'Enabled'
        else
          'Disabled'
        end encryption_status
      from
        aws_ec2_instance as i left join encrypted_instances as e on ((e.instanceid)::text = i.instance_id) and (i.root_device_name = (e.device)::text)
        ) as t
    group by
      encryption_status
    order by
      encryption_status
  EOQ
}

query "aws_ec2_instance_detailed_monitoring_enabled" {
  sql = <<-EOQ
    with instances as (
      select
        case
          when monitoring_state = 'enabled' then 'Enabled'
          else 'Disabled'
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

# COST
query "aws_ec2_instance_cost_per_month" {
  sql = <<-EOQ
    select
       to_char(period_start, 'Mon-YY') as "Month",
       sum(unblended_cost_amount)::numeric as "Unblended Cost"
       --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
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

query "aws_ec2_monthly_forecast_table" {

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

# query "aws_ec2_instance_cost_by_usage_types_12mo" {
#   sql = <<-EOQ
#     select
#        usage_type,
#        sum(unblended_cost_amount)::numeric as "Unblended Cost"
#        -- sum(unblended_cost_amount)::numeric::money as "Unblended Cost"

#     from
#       aws_cost_by_service_usage_type_monthly
#     where
#       service = 'Amazon Elastic Compute Cloud - Compute'
#       and period_end >=  CURRENT_DATE - INTERVAL '1 year'
#     group by
#       usage_type
#     having
#       round(sum(unblended_cost_amount)::numeric,2) > 0
#     order by
#       sum(unblended_cost_amount) desc
#   EOQ
# }

# query "aws_ec2_instance_cost_top_usage_types_mtd" {
#   sql = <<-EOQ
#     select
#        usage_type,
#        sum(unblended_cost_amount)::numeric as "Unblended Cost"
#        --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"

#     from
#       aws_cost_by_service_usage_type_monthly
#     where
#       service = 'Amazon Elastic Compute Cloud - Compute'
#       and period_end > date_trunc('month', CURRENT_DATE::timestamp)
#     group by
#       period_start,
#       usage_type
#     having
#       round(sum(unblended_cost_amount)::numeric,2) > 0
#     order by
#       sum(unblended_cost_amount) desc
#   EOQ
# }

# query "aws_ec2_instance_cost_by_account_mtd" {
#   sql = <<-EOQ
#     select
#        a.title as "account",
#        sum(unblended_cost_amount)::numeric as "Unblended Cost"
#        --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
#     from
#       aws_cost_by_service_monthly as c,
#       aws_account as a
#     where
#       a.account_id = c.account_id
#       and service = 'Amazon Elastic Compute Cloud - Compute'
#       and period_end > date_trunc('month', CURRENT_DATE::timestamp)
#     group by
#       account
#     order by
#       account
#   EOQ
# }

# query "aws_ec2_instance_cost_by_account_12mo" {
#   sql = <<-EOQ
#     select
#        a.title as "account",
#        sum(unblended_cost_amount)::numeric as "Unblended Cost"
#        --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
#     from
#       aws_cost_by_service_monthly as c,
#       aws_account as a
#     where
#       a.account_id = c.account_id
#       and service = 'Amazon Elastic Compute Cloud - Compute'
#       and period_end >=  CURRENT_DATE - INTERVAL '1 year'
#     group by
#       account
#     order by
#       account
#   EOQ
# }

# Analysis
query "aws_ec2_instance_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_ec2_instance as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc
  EOQ
}

query "aws_ec2_instance_by_region" {
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

query "aws_ec2_instance_by_state" {
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

query "aws_ec2_instance_by_creation_month" {
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
      months.month desc;
  EOQ
}

query "aws_ec2_instance_by_type" {
  sql = <<-EOQ
    select instance_type as "Type", count(*) as "instances" from aws_ec2_instance group by instance_type order by instance_type
  EOQ
}

# Note the CTE uses the dailt table to be efficient when filtering,
# and the hourly table to show granular line chart
query "aws_ec2_top10_cpu_past_week" {
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
      timestamp
  EOQ
}

# underused if avg CPU < 10% every day for last month
query "aws_ec2_instance_by_cpu_utilization_category" {
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
      b.cpu_bucket
  EOQ
}

dashboard "aws_ec2_instance_dashboard" {

  title = "AWS EC2 Instance Dashboard"

  container {

    # Analysis
    card {
      sql   = query.aws_ec2_instance_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ec2_instance_total_cores.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_ec2_public_instance_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ec2_ebs_optimized_count.sql
      width = 2
    }

     card {
      sql   = query.aws_ec2_root_volume_unencrypted_instance_count.sql
      width = 2
    }

   # Costs
   card {
      type  = "info"
      icon = "currency-dollar"

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
      width = 2
    }

  }

  container {
    title = "Assessments"
    width = 6

   chart {
      title = "Public/Private"
      sql   = query.aws_ec2_instance_by_public_ip.sql
      type  = "donut"
      width = 4
    }

    chart {
      title = "EBS Optimized Status"
      sql   = query.aws_ec2_instance_ebs_optimized_status.sql
      type  = "donut"
      width = 4
    }

    chart {
      title  = "Root Volume Encryption"
      sql    = query.aws_ec2_instance_root_volume_encryption_status.sql
      type   = "donut"
      width = 4
    }

    chart {
      title  = "Detailed Monitoring Status"
      sql    = query.aws_ec2_instance_detailed_monitoring_enabled.sql
      type   = "donut"
      width = 4
    }

  }

  container {
    title = "Costs"
    width = 6


    table  {
      width = 6
      title = "Forecast"
      sql = query.aws_ec2_monthly_forecast_table.sql
    }

    chart {
      width = 6
      title = "EC2 Compute Monthly Unblended Cost"
      type  = "column"
      sql   = query.aws_ec2_instance_cost_per_month.sql
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Instances by Account"
      sql   = query.aws_ec2_instance_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Instances by Region"
      sql   = query.aws_ec2_instance_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Instances by State"
      sql   = query.aws_ec2_instance_by_state.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Instances by Age"
      sql   = query.aws_ec2_instance_by_creation_month.sql
      type  = "column"
        width = 3
    }

    chart {
      title = "Instances by Type"
      sql   = query.aws_ec2_instance_by_type.sql
      type  = "column"
      width = 3
    }

  }

  container {
    title  = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days"
      sql   = query.aws_ec2_top10_cpu_past_week.sql
      type  = "line"
      width = 6
    }

    chart {
      title = "Average Max Daily CPU - Last 30 days"
      sql   = query.aws_ec2_instance_by_cpu_utilization_category.sql
      type  = "column"
      width = 3
    }
    
  }

}
