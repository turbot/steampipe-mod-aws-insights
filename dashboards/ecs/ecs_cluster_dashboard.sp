dashboard "ecs_cluster_dashboard" {

  title         = "AWS ECS Cluster Dashboard"
  documentation = file("./dashboards/ecs/docs/ecs_cluster_dashboard.md")

  tags = merge(local.ecs_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.ecs_cluster_count
      width = 3
    }

    card {
      query = query.ecs_cluster_active_service_count
      width = 3
    }

    # Assessments
    card {
      query = query.ecs_cluster_container_insights_disabled
      width = 3
    }


  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Container Insights Status"
      query = query.ecs_cluster_container_insights_status
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
      query = query.ecs_cluster_monthly_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.ecs_cluster_cost_per_month
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Clusters by Account"
      query = query.ecs_cluster_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Region"
      query = query.ecs_cluster_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Status"
      query = query.ecs_cluster_by_status
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "ecs_cluster_count" {
  sql = <<-EOQ
    select
      count(*) as "Clusters"
    from
      aws_ecs_cluster;
  EOQ
}

query "ecs_cluster_active_service_count" {
  sql = <<-EOQ
    select
      count(*) as "Cluster Active Services"
    from
      aws_ecs_cluster;
  EOQ
}

query "ecs_cluster_container_insights_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Container Insights Disabled' as label,
      case
        when count(*) > 0 then 'alert' else 'ok' end as "type"
    from
      aws_ecs_cluster as c,
      jsonb_array_elements(settings) as s
    where
      s ->> 'Name' = 'containerInsights' and s ->> 'Value' = 'disabled';
  EOQ
}

# Assessment Queries

query "ecs_cluster_container_insights_status" {
  sql = <<-EOQ
    select
      container_insights_status,
      count(*)
    from (
      select s ->> 'Value',
        case when s ->> 'Name' = 'containerInsights' and s ->> 'Value' = 'enabled' then
          'enabled'
        else
          'disabled'
        end container_insights_status
      from
        aws_ecs_cluster as c,
        jsonb_array_elements(settings) as s) as t
    group by
      container_insights_status
    order by
      container_insights_status desc;
  EOQ
}

# Cost Queries

query "ecs_cluster_monthly_forecast_table" {
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
        service = 'Amazon Elastic Container Service'
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

query "ecs_cluster_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Elastic Container Service'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "ecs_cluster_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(c.*) as "clusters"
    from
      aws_ecs_cluster as c,
      aws_account as a
    where
      a.account_id = c.account_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "ecs_cluster_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "clusters"
    from
      aws_ecs_cluster
    group by
      region
    order by
      region;
  EOQ
}

query "ecs_cluster_by_status" {
  sql = <<-EOQ
    select
      status as "Status",
      count(*) as "clusters"
    from
      aws_ecs_cluster
    group by
      status
    order by
      status;
  EOQ
}
