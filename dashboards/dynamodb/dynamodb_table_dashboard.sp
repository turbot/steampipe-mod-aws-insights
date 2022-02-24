query "aws_dynamodb_table_count" {
  sql = <<-EOQ
    select count(*) as "Tables" from aws_dynamodb_table;
  EOQ
}

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
      (select average_daily_cost from monthly_costs where period_label = 'Month to Date') as "Daily Avg Cost"

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

dashboard "aws_dynamodb_table_dashboard" {
  title = "AWS DynamoDB Table Dashboard"

  # Top cards
  container {
    card {
      sql   = query.aws_dynamodb_table_count.sql
      width = 2
    }

    # Unused Table
    card {
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
      width = 2
    }

    # Autoscaling
    card {
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
      width = 2
    }

    # Continuous Backup
    card {
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
      width = 2
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      sql   = <<-EOQ
        select
          'Cost - MTD' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_usage_type_monthly
        where
          service = 'Amazon DynamoDB'
          and period_end > date_trunc('month', CURRENT_DATE::timestamp);
      EOQ
    }

  }

  # Assessments
  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Unused Table Status"
      type  = "donut"
      width = 4
      sql   = <<-EOQ
        with table_status as (
          select
            name,
            case
              when item_count > 0 then 'In-Use'
              else 'Unused'
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

    chart {
      title = "Autoscaling Status"
      type  = "donut"
      width = 4
      sql   = <<-EOQ
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
            when t.resource_id is null or t.count < 2 then 'DISABLED'
            else 'ENABLED'
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

    chart {
        title = "Encryption Status"
        type  = "donut"
        width = 4
        sql   = <<-EOQ
          with table_encryption_status as (
            select
              t.name as table_name,
              case
                when t.sse_description ->> 'SSEType' = 'KMS' and k.key_manager = 'AWS' then 'AWS Managed'
                when t.sse_description ->> 'SSEType' = 'KMS' and k.key_manager = 'CUSTOMER' then 'Customer Managed'
                else 'DEFAULT'
              end as encryption_type
            from
              aws_dynamodb_table as t
              left join aws_kms_key as k on t.sse_description ->> 'KMSMasterKeyArn' = k.arn
          )
          select
            encryption_type,
            count(*) as table_count
          from
            table_encryption_status
          group by encryption_type;
        EOQ
      }
      chart {
        title = "Continuous Backup Status"
        type  = "donut"
        width = 4
        sql   = <<-EOQ
          select
            continuous_backups_status,
            count(*)
          from
            aws_dynamodb_table
          group by continuous_backups_status;
        EOQ
      }

      chart {
        title = "Backup Plan Protection Status"
        type  = "donut"
        width = 4
        sql   = <<-EOQ
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
                when b.arn is not null then 'Protected'
                else 'Unprotected'
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
    }

  # Costs
  container {
    title = "Costs"
    width = 6

    # Costs
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

  # Analysis
  container {
    title = "Analysis"

    chart {
      title = "Tables by Account"
      type  = "column"
      width = 3
      sql   = <<-EOQ
        select
          a.title as "account",
          count(t.*) as "volumes"
        from
          aws_dynamodb_table as t,
          aws_account as a
        where
          a.account_id = t.account_id
        group by account
        order by account;
      EOQ
    }

    chart {
      title = "Tables by Region"
      type  = "column"
      width = 3
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

    chart {
      title = "Table Item Count by Account"
      type  = "column"
      width = 2
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

    chart {
      title = "Table Item Count by Region"
      type  = "column"
      width = 2
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

    chart {
      title = "Tables by Age"
      sql   = query.aws_dynamodb_table_by_creation_month.sql
      type  = "column"
      width = 2
    }
  }

  # Performance & Utilization
  container {
    title = "Performance & Utilization"

    chart {
      title = "Average Read Throughput - Last 7 days"
      type  = "line"
      width = 6
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

    chart {
      title = "Average Write Throughput - Last 7 days"
      type  = "line"
      width = 6
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
  }
}
