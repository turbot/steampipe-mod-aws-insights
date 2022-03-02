dashboard "aws_redshift_cluster_dashboard" {

  title = "AWS Redshift Cluster Dashboard"

  tags = merge(local.redshift_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql = query.aws_redshift_cluster_count.sql
      width = 2
    }

    # Assessments
    card {
      sql = query.aws_redshift_cluster_unencrypted_count.sql
      width = 2
    }

    card {
      sql = query.aws_redshift_cluster_publicly_accessible.sql
      width = 2
    }

    card {
      sql   = query.aws_redshift_cluster_not_in_vpc.sql
      width = 2
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      sql   = query.aws_redshift_cluster_cost_mtd.sql
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      sql = query.aws_redshift_cluster_by_encryption_status.sql
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
      title = "Public Accessibility Status"
      sql = query.aws_redshift_cluster_by_publicly_accessible_status.sql
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
      title = "VPC Status"
      sql = query.aws_redshift_cluster_in_vpc_status.sql
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

    table  {
      width = 6
      title = "Forecast"
      sql   = query.aws_redshift_cluster_monthly_forecast_table.sql
    }

    chart {
      title = "Monthly Cost - 12 Months"
      type  = "column"
      sql   = query.aws_redshift_cluster_cost_per_month.sql
      width = 6
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Clusters by Account"
      sql = query.aws_redshift_cluster_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Clusters by Region"
      sql = query.aws_redshift_cluster_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Clusters by State"
      sql = query.aws_redshift_cluster_by_state.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Clusters by Age"
      sql = query.aws_redshift_cluster_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

  container {

    title  = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days"
      type  = "line"
      width = 6
      sql = query.aws_redshift_cluster_top10_cpu_past_week.sql
    }

    chart {
      title = "Average max daily CPU - Last 30 days"
      type  = "line"
      width = 6
      sql = query.aws_redshift_cluster_by_cpu_utilization_category.sql
    }

  }

}

# Card Queries

query "aws_redshift_cluster_count" {
  sql = <<-EOQ
    select count(*) as "Clusters" from aws_redshift_cluster
  EOQ
}

query "aws_redshift_cluster_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_redshift_cluster
    where
      not encrypted
  EOQ
}

query "aws_redshift_cluster_publicly_accessible" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Publicly Accessible' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_redshift_cluster
    where
      publicly_accessible
  EOQ
}

query "aws_redshift_cluster_not_in_vpc" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Not in VPC' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_redshift_cluster
    where
      vpc_id is null
  EOQ
}

query "aws_redshift_cluster_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_usage_type_monthly as c
    where
      service = 'Amazon Redshift'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp);
  EOQ
}

# Assessment Queries

query "aws_redshift_cluster_by_encryption_status" {
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
        aws_redshift_cluster) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "aws_redshift_cluster_by_publicly_accessible_status" {
  sql = <<-EOQ
    select
      publicly_accessible_status,
      count(*)
    from (
      select publicly_accessible,
        case when publicly_accessible then
          'public'
        else
          'private'
        end publicly_accessible_status
      from
        aws_redshift_cluster) as t
    group by
      publicly_accessible_status
    order by
      publicly_accessible_status desc;
  EOQ
}

query "aws_redshift_cluster_in_vpc_status" {
  sql = <<-EOQ
    select
      vpc_status,
      count(*)
    from (
      select
        case when vpc_id is not null then
          'enabled'
        else
          'disabled'
        end vpc_status
      from
        aws_redshift_cluster) as t
    group by
      vpc_status
    order by
      vpc_status desc;
  EOQ
}

# Cost Queries

query "aws_redshift_cluster_monthly_forecast_table" {
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
        service = 'Amazon Redshift'
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

query "aws_redshift_cluster_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Redshift'
    group by
      period_start
    order by
      period_start
  EOQ
}

# Analysis Queries

query "aws_redshift_cluster_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(v.*) as "Clusters"
    from
      aws_redshift_cluster as v,
      aws_account as a
    where
      a.account_id = v.account_id
    group by
      a.title
    order by
      a.title
  EOQ
}

query "aws_redshift_cluster_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "clusters" from aws_redshift_cluster group by region order by region
  EOQ
}

query "aws_redshift_cluster_by_state" {
  sql = <<-EOQ
    select
      cluster_status,
      count(cluster_status)
    from
      aws_redshift_cluster
    group by
      cluster_status
  EOQ
}

query "aws_redshift_cluster_by_creation_month" {
  sql = <<-EOQ
    with clusters as (
      select
        title,
        cluster_create_time,
        to_char(cluster_create_time,
          'YYYY-MM') as creation_month
      from
        aws_redshift_cluster
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(cluster_create_time)
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

# Performance Queries

query "aws_redshift_cluster_top10_cpu_past_week" {
  sql = <<-EOQ
    with top_n as (
      select
        cluster_identifier,
        avg(average)
      from
        aws_redshift_cluster_metric_cpu_utilization_daily
      where
        timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      group by
        cluster_identifier
      order by
        avg desc
      limit 10
    )
    select
      timestamp,
      cluster_identifier,
      maximum
    from
      aws_redshift_cluster_metric_cpu_utilization_daily
    where
      timestamp  >= CURRENT_DATE - INTERVAL '7 day'
      and cluster_identifier in (select cluster_identifier from top_n)
    order by
      timestamp;
  EOQ
}

query "aws_redshift_cluster_by_cpu_utilization_category" {
  sql = <<-EOQ
    with cpu_buckets as (
      select
        unnest(array ['Unused (<1%)','Underutilized (1-10%)','Right-sized (10-90%)', 'Overutilized (>90%)' ])     as cpu_bucket
    ),
    max_averages as (
      select
        cluster_identifier,
        case
          when max(average) <= 1 then 'Unused (<1%)'
          when max(average) between 1 and 10 then 'Underutilized (1-10%)'
          when max(average) between 10 and 90 then 'Right-sized (10-90%)'
          when max(average) > 90 then 'Overutilized (>90%)'
        end as cpu_bucket,
        max(average) as max_avg
      from
        aws_redshift_cluster_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        cluster_identifier
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