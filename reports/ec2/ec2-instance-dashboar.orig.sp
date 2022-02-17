query "deleteme_aws_ec2_instance_count" {
  sql = <<-EOQ
    select count(*) as "Instances" from aws_ec2_instance
  EOQ
}

query "deleteme_aws_ec2_instance_total_cores" {
  sql = <<-EOQ
    select
      sum(cpu_options_core_count)  as "Total Cores"
    from
      aws_ec2_instance as i
  EOQ
}

query "deleteme_aws_ec2_public_instance_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Instances' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ec2_instance
    where
      public_ip_address is not null
  EOQ
}

query "deleteme_aws_ec2_unencrypted_instance_count" {
  sql = <<-EOQ
    select
       999 as value,
      'TODO: Unencrypted Instances' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
  EOQ
}

query "deleteme_aws_ec2_instance_cost_per_month" {
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

query "deleteme_aws_ec2_instance_cost_by_usage_types_12mo" {
  sql = <<-EOQ
    select
       usage_type,
       sum(unblended_cost_amount)::numeric as "Unblended Cost"
       -- sum(unblended_cost_amount)::numeric::money as "Unblended Cost"

    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Elastic Compute Cloud - Compute'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      usage_type
    having
      round(sum(unblended_cost_amount)::numeric,2) > 0
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "deleteme_aws_ec2_instance_cost_top_usage_types_mtd" {
  sql = <<-EOQ
    select
       usage_type,
       sum(unblended_cost_amount)::numeric as "Unblended Cost"
       --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"

    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Elastic Compute Cloud - Compute'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
    group by
      period_start,
      usage_type
    having
      round(sum(unblended_cost_amount)::numeric,2) > 0
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "deleteme_aws_ec2_instance_cost_by_account_mtd" {
  sql = <<-EOQ
    select
       a.title as "account",
       sum(unblended_cost_amount)::numeric as "Unblended Cost"
       --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'Amazon Elastic Compute Cloud - Compute'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
    group by
      account
    order by
      account
  EOQ
}

query "deleteme_aws_ec2_instance_cost_by_account_12mo" {
  sql = <<-EOQ
    select
       a.title as "account",
       sum(unblended_cost_amount)::numeric as "Unblended Cost"
       --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'Amazon Elastic Compute Cloud - Compute'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      account
    order by
      account
  EOQ
}

query "deleteme_aws_ec2_instance_by_account" {
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

query "deleteme_aws_ec2_instance_by_region" {
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

query "deleteme_aws_ec2_instance_by_type" {
  sql = <<-EOQ
    select instance_type as "Type", count(*) as "instances" from aws_ec2_instance group by instance_type order by instance_type
  EOQ
}

query "deleteme_aws_ec2_instance_by_state" {
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


query "deleteme_aws_ec2_instance_by_public_ip" {
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

query "deleteme_aws_ec2_instance_with_public_ip" {
  sql = <<-EOQ
    select
      instance_id,
      public_ip_address,
      account_id,
      region
    from
      aws_ec2_instance
    where
      public_ip_address is not null
  EOQ
}

query "deleteme_aws_ec2_instance_by_creation_month" {
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

# Note the CTE uses the dailt table to be efficient when filtering,
# and the hourly table to show granular line chart
query "deleteme_aws_ec2_top10_cpu_past_week" {
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
query "deleteme_aws_ec2_instance_by_cpu_utilization_category" {
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

dashboard "aws_ec2_instance_dashboard_orig" {

  title = "AWS EC2 Instance Dashboard [Old]"

  container {

    # Analysis
    card {
      sql   = query.deleteme_aws_ec2_instance_count.sql
      width = 2
    }

    card {
      sql   = query.deleteme_aws_ec2_instance_total_cores.sql
      width = 2
    }


   # Costs
   card {
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

  card {
      sql = <<-EOQ
        select
          'Cost - Previous Month' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_monthly
        where
          service = 'Amazon Elastic Compute Cloud - Compute'
          and date_trunc('month', period_start) =  date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
      EOQ
      width = 2
    }

    # Assessments
    card {
      sql   = query.deleteme_aws_ec2_public_instance_count.sql
      width = 2
    }

    card {
      sql   = query.deleteme_aws_ec2_unencrypted_instance_count.sql
      width = 2
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "Instances by Account"
      sql   = query.deleteme_aws_ec2_instance_by_account.sql
      type  = "column"
      width = 3
    }


    chart {
      title = "Instances by Region"
      sql   = query.deleteme_aws_ec2_instance_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Instances by State"
      sql   = query.deleteme_aws_ec2_instance_by_state.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Instances by Type"
      sql   = query.deleteme_aws_ec2_instance_by_type.sql
      type  = "column"
      width = 3
    }
  }

  container {
    title = "Costs"

    chart {
      title = "EC2 Compute Monthly Unblended Cost"
      type  = "line"
      sql   = query.deleteme_aws_ec2_instance_cost_per_month.sql
      width = 4
    }

   chart {
      title = "EC2 Cost by Usage Type - MTD"
      type  = "donut"
      sql   = query.deleteme_aws_ec2_instance_cost_top_usage_types_mtd.sql
      width = 2

      legend {
        position  = "bottom"
      }
    }

   chart {
      title = "EC2 Cost by Usage Type - 12 months"
      type  = "donut"
      sql   = query.deleteme_aws_ec2_instance_cost_by_usage_types_12mo.sql
      width = 2

      legend {
        position  = "right"
      }
    }

    chart {
      title = "EC2 Cost by Account - MTD"
      type  = "donut"
      sql   = query.deleteme_aws_ec2_instance_cost_by_account_mtd.sql
      width = 2
    }

    chart {
      title = "EC2 Cost by Account - 12 months"
      type  = "donut"
      sql   = query.deleteme_aws_ec2_instance_cost_by_account_12mo.sql
      width = 2
    }

  }

  container {
    title = "Assesments"
    width = 6

    chart {
      title  = "Encryption Status [TODO]"
      # sql    = query.deleteme_aws_ec2_instance_by_encryption_status.sql
      # type   = "donut"
      width = 4
    }

   chart {
      title = "Public/Private"
      sql   = query.deleteme_aws_ec2_instance_by_public_ip.sql
      type  = "donut"
      width = 4
    }
  }

  container {
    title  = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days"
      sql   = query.deleteme_aws_ec2_top10_cpu_past_week.sql
      type  = "line"
      width = 6
    }

    chart {
      title = "Average max daily CPU - Last 30 days"
      sql   = query.deleteme_aws_ec2_instance_by_cpu_utilization_category.sql
      type  = "column"
      width = 6
    }
  }

  container {
    title   = "Resources by Age"

    chart {
      title = "Instance by Creation Month"
      sql   = query.deleteme_aws_ec2_instance_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest instances"
      width = 4

      sql = <<-EOQ
        select
          title as "instance",
          (current_date - launch_time)::text as "Age in Days",
          account_id as "Account"
        from
          aws_ec2_instance
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest instances"
      width = 4

      sql = <<-EOQ
        select
          title as "instance",
          current_date - launch_time as "Age in Days",
          account_id as "Account"
        from
          aws_ec2_instance
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }
  }

}
