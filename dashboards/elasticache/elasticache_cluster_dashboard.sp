dashboard "aws_elasticache_cluster_dashboard" {

  title         = "AWS ElastiCache Cluster Dashboard"
  documentation = file("./dashboards/elasticache/docs/elasticache_cluster_dashboard.md")

  tags = merge(local.elasticache_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.aws_elasticache_cluster_count
      width = 2
    }

    card {
      query = query.aws_elasticache_cluster_cache_node_count
      width = 2
    }

    # Assessments
    card {
      query = query.aws_elasticache_cluster_encryption_at_rest_disabled_count
      width = 2
    }

    card {
      query = query.aws_elasticache_cluster_encryption_at_transit_disabled_count
      width = 2
    }

    card {
      query = query.aws_elasticache_cluster_automatic_backup_disabled_count
      width = 2
    }

    # Costs

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption at Rest"
      query = query.aws_elasticache_cluster_by_encryption_at_rest_status
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
      title = "Encryption in Transit"
      query = query.aws_elasticache_cluster_by_encryption_at_transit_status
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
      title = "Automatic Backup Status"
      query = query.aws_elasticache_cluster_by_automatic_backup_status
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
      query = query.aws_elasticache_cluster_monthly_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.aws_elasticache_cluster_cost_per_month
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Clusters by Account"
      query = query.aws_elasticache_cluster_by_account
      type  = "column"
      width = 3
    }

    chart {
      title = "Clusters by Region"
      query = query.aws_elasticache_cluster_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Clusters by Engine"
      query = query.aws_elasticache_cluster_by_engine
      type  = "column"
      width = 3
    }

    chart {
      title = "Clusters by Age"
      query = query.aws_elasticache_cluste_by_creation_month
      type  = "column"
      width = 3
    }

    chart {
      title = "Clusters by Node Type"
      query = query.aws_elasticache_cluster_by_node_type
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "aws_elasticache_cluster_count" {
  sql = <<-EOQ
    select
      count(*) as "Clusters"
    from
      aws_elasticache_cluster;
  EOQ
}

query "aws_elasticache_cluster_cache_node_count" {
  sql = <<-EOQ
    select
      count(num_cache_nodes) as "Cache Nodes"
    from
      aws_elasticache_cluster;
  EOQ
}

query "aws_elasticache_cluster_encryption_at_rest_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Encryption at Rest Disabled' as label,
      case
        when count(*) > 0 then 'alert' else 'ok' end as "type"
    from
      aws_elasticache_cluster
    where
      not at_rest_encryption_enabled;
  EOQ
}

query "aws_elasticache_cluster_encryption_at_transit_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Encryption in Transit Disabled' as label,
      case
        when count(*) > 0 then 'alert' else 'ok' end as "type"
    from
      aws_elasticache_cluster
    where
      not transit_encryption_enabled;
  EOQ
}

query "aws_elasticache_cluster_automatic_backup_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Automatic Backup Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_elasticache_cluster
    where
      snapshot_retention_limit is null;
  EOQ
}

# Assessment Queries

query "aws_elasticache_cluster_by_encryption_at_rest_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select at_rest_encryption_enabled,
        case when at_rest_encryption_enabled then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_elasticache_cluster) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "aws_elasticache_cluster_by_encryption_at_transit_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select transit_encryption_enabled,
        case when transit_encryption_enabled then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_elasticache_cluster) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "aws_elasticache_cluster_by_automatic_backup_status" {
  sql = <<-EOQ
    select
      automatic_backup_status,
      count(*)
    from (
      select snapshot_retention_limit,
        case when snapshot_retention_limit is not null then
          'enabled'
        else
          'disabled'
        end automatic_backup_status
      from
        aws_elasticache_cluster) as a
    group by
      automatic_backup_status
    order by
      automatic_backup_status desc;
  EOQ
}

# Cost Queries

query "aws_elasticache_cluster_monthly_forecast_table" {
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
        service = 'Amazon ElastiCache'
        and usage_type like '%NodeUsage:cache%'
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

query "aws_elasticache_cluster_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon ElastiCache'
      and usage_type like '%NodeUsage:cache%'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "aws_elasticache_cluster_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(c.*) as "clusters"
    from
      aws_elasticache_cluster as c,
      aws_account as a
    where
      a.account_id = c.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "aws_elasticache_cluster_by_engine" {
  sql = <<-EOQ
    select
      engine as "Type",
      count(*) as "clusters"
    from
      aws_elasticache_cluster
    group by
      engine
    order by
      engine;
  EOQ
}

query "aws_elasticache_cluster_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "clusters"
    from
      aws_elasticache_cluster
    group by
      region
    order by
      region;
  EOQ
}

query "aws_elasticache_cluster_by_node_type" {
  sql = <<-EOQ
    select
      cache_node_type as "Type",
      count(*) as "cache nodes"
    from
      aws_elasticache_cluster
    group by
      cache_node_type
    order by
      cache_node_type;
  EOQ
}

query "aws_elasticache_cluste_by_creation_month" {
  sql = <<-EOQ
    with clusters as (
      select
        title,
        cache_cluster_create_time,
        to_char(cache_cluster_create_time,
          'YYYY-MM') as creation_month
      from
        aws_elasticache_cluster
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(cache_cluster_create_time)
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
