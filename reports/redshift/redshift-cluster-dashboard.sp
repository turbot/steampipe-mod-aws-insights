query "aws_redshift_cluster_count" {
  sql = <<-EOQ
    select count(*) as "Clusters" from aws_redshift_cluster
  EOQ
}

query "aws_redshift_cluster_encrypted_count" {
  sql = <<-EOQ
    select 
      count(*) as value,
      'Unencrypted Clusters' as label,
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
      'Publicly Accessible Clusters' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from 
      aws_redshift_cluster 
    where 
      publicly_accessible
  EOQ
}

query "aws_redshift_cluster_in_vpc" {
  sql = <<-EOQ
    select 
      count(*) as value,
      'Clusters in VPC' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_redshift_cluster 
    where 
      vpc_id is null
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

# query "aws_redshift_cluster_cost_by_usage_types_mtd" {
#   sql = <<-EOQ
#     select
#        usage_type,
#        sum(unblended_cost_amount) as "Unblended Cost"
#     from
#       aws_cost_by_service_usage_type_monthly as c
#     where
#       service = 'Amazon Redshift'
#       and period_end > date_trunc('month', CURRENT_DATE::timestamp)
#     group by
#       usage_type
#     having
#       round(sum(unblended_cost_amount)::numeric,2) > 0
#     order by
#       sum(unblended_cost_amount) desc
#   EOQ
# }

# query "aws_redshift_cluster_cost_per_month_stacked" {
#   sql = <<-EOQ
#     select
#       to_char(period_start, 'Mon-YY') as "Month",
#       usage_type as "Usage Type",
#       sum(unblended_cost_amount) as "Unblended Cost"
#     from
#       aws_cost_by_service_usage_type_monthly
#     where
#       service = 'Amazon Redshift'
#     group by
#       period_start,
#       usage_type
#     order by
#       period_start
#   EOQ
# }

# query "aws_redshift_cluster_cost_by_usage_types_12mo" {
#   sql = <<-EOQ
#     select
#        usage_type,
#        sum(unblended_cost_amount) as "Unblended Cost"
#     from
#       aws_cost_by_service_usage_type_monthly as c
#     where
#       service = 'Amazon Redshift'
#       and period_end >=  CURRENT_DATE - INTERVAL '1 year'
#     group by
#       usage_type
#     having
#       round(sum(unblended_cost_amount)::numeric,2) > 0
#     order by
#       sum(unblended_cost_amount) desc
#   EOQ
# }

# query "aws_redshift_cluster_cost_by_account_mtd" {
#   sql = <<-EOQ
#     select
#        a.title as "account",
#        sum(unblended_cost_amount) as "Unblended Cost"
#     from
#       aws_cost_by_service_usage_type_monthly as c,
#       aws_account as a
#     where
#       a.account_id = c.account_id
#       and service = 'Amazon Redshift'
#       and period_end > date_trunc('month', CURRENT_DATE::timestamp)
#     group by
#       account
#     order by
#       account
#   EOQ
# }

# query "aws_redshift_cluster_cost_by_account_12mo" {
#   sql = <<-EOQ
#     select
#        a.title as "account",
#        sum(unblended_cost_amount) as "Unblended Cost"
#     from
#       aws_cost_by_service_usage_type_monthly as c,
#       aws_account as a
#     where
#       a.account_id = c.account_id
#       and service = 'Amazon Redshift'
#       and period_end >=  CURRENT_DATE - INTERVAL '1 year'
#     group by
#       account
#     order by
#       account
#   EOQ
# }

query "aws_redshift_cluster_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(v.*) as "clusters"
    from
      aws_redshift_cluster as v,
      aws_account as a
    where
      a.account_id = v.account_id
    group by
      account
    order by
      account
  EOQ
}

query "aws_redshift_cluster_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "clusters" from aws_redshift_cluster group by region order by region
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
          'Public'
        else
          'Private'
        end publicly_accessible_status
      from
        aws_redshift_cluster) as t
    group by
      publicly_accessible_status
    order by
      publicly_accessible_status desc
  EOQ
}

query "aws_redshift_cluster_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select encrypted,
        case when encrypted then
          'Enabled'
        else
          'Disabled'
        end encryption_status
      from
        aws_redshift_cluster) as t
    group by
      encryption_status
    order by
      encryption_status desc
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

query "aws_redshift_cluster_with_no_snapshots" {
  sql = <<-EOQ
    select
      v.cluster_identifier,
      v.account_id,
      v.region
    from
      aws_redshift_cluster as v
    left join aws_redshift_snapshot as s on v.cluster_identifier = s.cluster_identifier
    group by
      v.account_id,
      v.region,
      v.cluster_identifier
    having
      count(s.snapshot_identifier) = 0
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

dashboard "aws_redshift_cluster_dashboard" {

  title = "AWS Redshift Cluster Dashboard"

  container {

    # Analysis

    card {
      sql = query.aws_redshift_cluster_count.sql
      width = 2
    }

    card {
      sql = query.aws_redshift_cluster_encrypted_count.sql
      width = 2
    }

    card {
      sql = query.aws_redshift_cluster_publicly_accessible.sql
      width = 2
    }

    card {
      sql = query.aws_redshift_cluster_in_vpc.sql
      width = 2
    }

  # Costs
    card {
        sql = <<-EOQ
          select
            'Cost - MTD' as label,
            sum(unblended_cost_amount)::numeric::money as value
          from
            aws_cost_by_service_usage_type_monthly as c
          where
            service = 'Amazon Redshift'
            and period_end > date_trunc('month', CURRENT_DATE::timestamp)
        EOQ
        type = "info"
        icon = "currency-dollar"
        width = 2
        }

    card {
        sql = <<-EOQ
          select
            'Cost - Previous Month' as label,
            sum(unblended_cost_amount)::numeric::money as value
          from
            aws_cost_by_service_usage_type_monthly as c
          where
            service = 'Amazon Redshift'
            and date_trunc('month', period_start) =  date_trunc('month', CURRENT_DATE::timestamp - interval  '1 month')
        EOQ
        type = "info"
        icon = "currency-dollar"
        width = 2
        }
   }
    # Assessments

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

  }

  container {
    title = "Costs"
    chart {
      title = "Redshift Cluster Monthly Unblended Cost"

      type  = "line"
      sql   = query.aws_redshift_cluster_cost_per_month.sql
      width = 4
    }

   chart {
      title = "Redshift Cluster Cost by Usage Type - MTD"
      type  = "donut"
      sql   = query.aws_redshift_cluster_cost_by_usage_types_mtd.sql
      width = 2
    }

   chart {
      title = "Redshift Cluster Cost by Usage Type - 12 months"
      type  = "donut"
      sql   = query.aws_redshift_cluster_cost_by_usage_types_12mo.sql
      width = 2
    }

    chart {
      title = "Redshift Cluster Cost By Account - MTD"

      type  = "donut"
      sql   = query.aws_redshift_cluster_cost_by_account_mtd.sql
      width = 2
    }

    chart {
      title = "Redshift Cluster Cost By Account - 12 months"

      type  = "donut"
      sql   = query.aws_redshift_cluster_cost_by_account_12mo.sql
      width = 2
    }
  }

  # donut charts in a 2 x 2 layout
  container {
    title = "Assessments"

    chart {
      title = "Encryption Status"
      sql = query.aws_redshift_cluster_by_encryption_status.sql
      type  = "donut"
      width = 2

      series "Enabled" {
         color = "green"
      }
    }

    chart {
      title = "Public Accessibility"
      sql = query.aws_redshift_cluster_by_publicly_accessible_status.sql
      type  = "donut"
      width = 2

    }

    chart {
      title = "Cluster State"
      sql = query.aws_redshift_cluster_by_state.sql
      type  = "donut"
      width = 2
    }
  }

  container {
    title = "Costs"
    chart {
      title = "Redshift Cluster Monthly Unblended Cost"

      type  = "line"
      sql   = query.aws_redshift_cluster_cost_per_month.sql
      width = 4
    }

  #  chart {
  #     title = "Redshift Cluster Cost by Usage Type - MTD"
  #     type  = "donut"
  #     sql   = query.aws_redshift_cluster_cost_by_usage_types_mtd.sql
  #     width = 2
  #   }

  #  chart {
  #     title = "Redshift Cluster Cost by Usage Type - 12 months"
  #     type  = "donut"
  #     sql   = query.aws_redshift_cluster_cost_by_usage_types_12mo.sql
  #     width = 2
  #   }

  #   chart {
  #     title = "Redshift Cluster Cost By Account - MTD"

  #     type  = "donut"
  #     sql   = query.aws_redshift_cluster_cost_by_account_mtd.sql
  #     width = 2
  #   }

  #   chart {
  #     title = "Redshift Cluster Cost By Account - 12 months"

  #     type  = "donut"
  #     sql   = query.aws_redshift_cluster_cost_by_account_12mo.sql
  #     width = 2
  #   }
  }

  # donut charts in a 2 x 2 layout


  container {
    title  = "Performance & Utilization"

    chart {
      title = "Top 10 CPU - Last 7 days"
      type  = "line"
      width = 4
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
          timestamp
      EOQ
    }

    chart {
      title = "Average max daily CPU - Last 30 days"
      type  = "line"
      width = 4
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
          b.cpu_bucket
      EOQ
    }
  }

  container {
    title = "Resources by Age"

    chart {
      title = "Cluster by Creation Month"
      sql = query.aws_redshift_cluster_by_creation_month.sql
      type  = "column"
      width = 4
      series "month" {
        color = "green"
      }
    }

  }

}