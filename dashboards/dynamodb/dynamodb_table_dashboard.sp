dashboard "aws_dynamodb_table_dashboard" {

  title         = "AWS DynamoDB Table Dashboard"
  documentation = file("./dashboards/dynamodb/docs/dynamodb_table_dashboard.md")

  tags = merge(local.dynamodb_common_tags, {
    type = "Dashboard"
  })

  # Top cards
  container {

    # Analysis
    card {
      sql   = query.aws_dynamodb_table_count.sql
      width = 2
    }

    # Assessments
    card {
      sql = query.aws_dynamodb_table_unused_count.sql
      width = 2
    }

    card {
      sql = query.aws_dynamodb_table_autoscaling_disabled_count.sql
      width = 2
    }

    card {
      sql = query.aws_dynamodb_table_continuous_backup_count.sql
      width = 2
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      sql   = query.aws_dynamodb_table_cost_mtd.sql
    }

  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Unused Table Status"
      type  = "donut"
      width = 4
      sql   = query.aws_dynamodb_table_unused_status.sql

      series "table_count" {
        point "in-use" {
          color = "ok"
        }
        point "unused" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Autoscaling Status"
      type  = "donut"
      width = 4
      sql   = query.aws_dynamodb_table_autoscaling_status.sql

      series "table_count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Continuous Backups"
      type  = "donut"
      width = 4
      sql   = query.aws_dynamodb_table_continuous_backup_status.sql

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
      title = "Backup Plan Protection"
      type  = "donut"
      width = 4
      sql   = query.aws_dynamodb_table_backup_plan_protection_status.sql

      series "table_count" {
        point "protected" {
          color = "ok"
        }
        point "unprotected" {
          color = "alert"
        }
      }
    }
  }

  container {
    title = "Costs"
    width = 6

    table  {
      width = 6
      title = "Forecast"
      sql   = query.aws_dynamodb_monthly_forecast_table.sql
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      sql   = query.aws_dynamodb_table_cost_per_month.sql
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Tables by Account"
      type  = "column"
      width = 4
      sql   = query.aws_dynamodb_table_by_account.sql
    }

    chart {
      title = "Tables by Region"
      type  = "column"
      width = 4
      sql   = query.aws_dynamodb_table_by_region.sql
    }

    chart {
      title = "Tables by Age"
      sql   = query.aws_dynamodb_table_by_creation_month.sql
      type  = "column"
      width = 4
    }
  }

  container {

    chart {
      title = "Table Item Count by Account"
      type  = "column"
      width = 4
      sql   = query.aws_dynamodb_table_item_count_by_account.sql

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Table Item Count by Region"
      type  = "column"
      width = 4
      sql   = query.aws_dynamodb_table_item_count_by_region.sql

      series "GB" {
        color = "tan"
      }
    }
  }

  container {
    title = "Performance & Utilization"

    chart {
      title = "Average Read Throughput - Last 7 days"
      type  = "line"
      width = 6
      sql   = query.aws_dynamodb_table_average_read_throughput.sql
    }

    chart {
      title = "Average Write Throughput - Last 7 days"
      type  = "line"
      width = 6
      sql   = query.aws_dynamodb_table_average_write_throughput.sql
    }

  }
}

# Card Queries

query "aws_dynamodb_table_count" {
  sql = <<-EOQ
    select count(*) as "Tables" from aws_dynamodb_table;
  EOQ
}

query "aws_dynamodb_table_unused_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unused' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_dynamodb_table
    where
      item_count = 0;
  EOQ
}

query "aws_dynamodb_table_autoscaling_disabled_count" {
  sql = <<-EOQ
    with table_with_autoscaling as (
      select
        t.resource_id as resource_id,
        count(t.resource_id) as count
      from
        aws_appautoscaling_target as t where service_namespace = 'dynamodb'
        group by t.resource_id
    )
    select
      count(*) as value,
      'Autoscaling Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_dynamodb_table as d
      left join table_with_autoscaling as t on concat('table/', d.name) = t.resource_id
    where
      t.resource_id is null
      or t.count < 2;
  EOQ
}

query "aws_dynamodb_table_continuous_backup_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Continuous Backup Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_dynamodb_table
    where
      not (continuous_backups_status = 'ENABLED');
  EOQ
}

query "aws_dynamodb_table_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_usage_type_monthly as c
    where
      service = 'Amazon DynamoDB'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp);
  EOQ
}

# Assessment Queries

query "aws_dynamodb_table_unused_status" {
  sql = <<-EOQ
    with table_status as (
      select
        name,
        case
          when item_count > 0 then 'in-use'
          else 'unused'
        end as table_usage_status
      from
        aws_dynamodb_table
    )
    select
      table_usage_status,
      count(*) as table_count
    from
      table_status
    group by table_usage_status;
  EOQ
}

query "aws_dynamodb_table_autoscaling_status" {
  sql = <<-EOQ
    with table_with_autoscaling as (
      select
        t.resource_id as resource_id,
        count(t.resource_id) as count
      from
        aws_appautoscaling_target as t where service_namespace = 'dynamodb'
        group by t.resource_id
    ),
    table_autoscaling_status as (
      select
      d.name as table_name,
      case
        when t.resource_id is null or t.count < 2 then 'disabled'
        else 'enabled'
      end as autoscaling_status
      from
        aws_dynamodb_table as d
        left join table_with_autoscaling as t on concat('table/', d.name) = t.resource_id
    )
    select
      autoscaling_status,
      count(*) as table_count
    from
      table_autoscaling_status
    group by autoscaling_status;
  EOQ
}

query "aws_dynamodb_table_continuous_backup_status" {
  sql = <<-EOQ
    select
      case
        when continuous_backups_status = 'ENABLED' then 'enabled'
        else 'disabled'
      end as status,
      count(*)
    from
      aws_dynamodb_table
    group by status;
  EOQ
}

query "aws_dynamodb_table_backup_plan_protection_status" {
  sql = <<-EOQ
    with backup_protected_table as (
      select
        resource_arn as arn
      from
        aws_backup_protected_resource as b
      where
        resource_type = 'DynamoDB'
    ),
    table_backup_plan_protection_status as (
      select
        t.name as table_name,
        case
          when b.arn is not null then 'protected'
          else 'unprotected'
        end as backup_plan_protection_status
      from
        aws_dynamodb_table as t
        left join backup_protected_table as b on t.arn = b.arn
    )
    select
      backup_plan_protection_status,
      count(*) as table_count
    from
      table_backup_plan_protection_status
    group by backup_plan_protection_status;
  EOQ
}

# Cost Queries

query "aws_dynamodb_monthly_forecast_table" {
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
        service = 'Amazon DynamoDB'
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

query "aws_dynamodb_table_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon DynamoDB'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "aws_dynamodb_table_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(t.*) as "tables"
    from
      aws_dynamodb_table as t,
      aws_account as a
    where
      a.account_id = t.account_id
    group by account
    order by account;
  EOQ
}

query "aws_dynamodb_table_by_region" {
  sql   = <<-EOQ
    select
      region as "Region",
      count(*) as "tables"
    from
      aws_dynamodb_table
    group by region
    order by region;
  EOQ
}

query "aws_dynamodb_table_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        creation_date_time,
        to_char(creation_date_time,
          'YYYY-MM') as creation_month
      from
        aws_dynamodb_table
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(creation_date_time)
              from
                volumes
            )),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    tables_by_month as (
      select
        creation_month,
        count(*)
      from
        volumes
      group by
        creation_month
    )
    select
      months.month,
      tables_by_month.count
    from
      months
      left join tables_by_month on months.month = tables_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "aws_dynamodb_table_item_count_by_account" {
  sql   = <<-EOQ
    select
      a.title as "account",
      sum(t.item_count) as "Count"
    from
      aws_dynamodb_table as t,
      aws_account as a
    where
      a.account_id = t.account_id
    group by account
    order by account;
  EOQ
}

query "aws_dynamodb_table_item_count_by_region" {
  sql   = <<-EOQ
    select
      region as "Region",
      sum(item_count) as "Count"
    from
      aws_dynamodb_table
    group by region
    order by region;
  EOQ
}

# Performance Queries

query "aws_dynamodb_table_average_read_throughput" {
  sql   =  <<-EOQ
    select
      timestamp,
      average
    from
      aws_dynamodb_metric_account_provisioned_read_capacity_util
    where
      timestamp >= current_date - interval '7 day'
    order by timestamp;
  EOQ
}

query "aws_dynamodb_table_average_write_throughput" {
  sql   =  <<-EOQ
    select
      timestamp,
      average
    from
      aws_dynamodb_metric_account_provisioned_write_capacity_util
    where
      timestamp >= current_date - interval '7 day'
    order by timestamp;
  EOQ
}

