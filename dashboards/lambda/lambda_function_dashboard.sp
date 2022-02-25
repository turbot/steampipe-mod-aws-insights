query "aws_lambda_function_count" {
  sql = <<-EOQ
    select count(*) as "Functions" from aws_lambda_function
  EOQ
}

query "aws_lambda_function_memory_total" {
  sql = <<-EOQ
    select
      round(cast(sum(memory_size)/1024 as numeric), 1) as "Total Memory(GB)"
    from
      aws_lambda_function
  EOQ
}

query "aws_lambda_function_public_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Lambda Functions' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_lambda_function
    where
      policy_std -> 'Statement' ->> 'Effect' = 'Allow'
    and (
      policy_std -> 'Statement' ->> 'Prinipal' = '*'
      or ( policy_std -> 'Principal' -> 'AWS' ) :: text = '*'
    );
  EOQ
}

query "aws_lambda_function_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_lambda_function
    where
      kms_key_arn is null;
  EOQ
}

query "aws_lambda_function_not_in_vpc_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Not In VPC' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_lambda_function
    where
      vpc_id is null;
  EOQ
}

# Assessments

query "aws_lambda_function_public_status" {
  sql = <<-EOQ
    with functions as (
      select
        case
          when
          policy_std -> 'Statement' ->> 'Effect' = 'Allow'
          and ( policy_std -> 'Statement' ->> 'Prinipal' = '*'
          or ( policy_std -> 'Principal' -> 'AWS' ) :: text = '*'
        ) then 'Public'
          else 'Private'
        end as visibility
      from
        aws_lambda_function
    )
    select
      visibility,
      count(*)
    from
      functions
    group by
      visibility;
  EOQ
}

query "aws_lambda_function_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select
        case when kms_key_arn is not null then
          'Enabled'
        else
          'Disabled'
        end encryption_status
      from
        aws_lambda_function) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "aws_lambda_function_vpc_status" {
  sql = <<-EOQ
    select
      vpc_status,
      count(*)
    from (
      select
        case when vpc_id is not null then
          'Enabled'
        else
          'Disabled'
        end vpc_status
      from
        aws_lambda_function) as t
    group by
      vpc_status
    order by
      vpc_status desc;
  EOQ
}

query "aws_lambda_function_use_latest_runtime_status" {
  sql = <<-EOQ
    select
      runtime_status,
      count(*)
    from (
      select
        case when runtime not in ('nodejs14.x', 'nodejs12.x', 'nodejs10.x', 'python3.8', 'python3.7', 'python3.6', 'ruby2.5', 'ruby2.7', 'java11', 'java8', 'go1.x', 'dotnetcore2.1', 'dotnetcore3.1') then
          'Disabled'
        else
          'Enabled'
        end runtime_status
      from
        aws_lambda_function) as t
    group by
      runtime_status
    order by
      runtime_status desc;
  EOQ
}

query "aws_lambda_function_dead_letter_config_status" {
  sql = <<-EOQ
    select
      dead_letter_config_status,
      count(*)
    from (
      select
        case when dead_letter_config_target_arn is not null then
          'Enabled'
        else
          'Disabled'
        end dead_letter_config_status
      from
        aws_lambda_function) as t
      group by
        dead_letter_config_status
      order by
        dead_letter_config_status desc;
  EOQ
}

# Cost
query "aws_lambda_function_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'AWS Lambda'
    group by
      period_start
    order by
      period_start;
  EOQ
}

query "aws_lambda_monthly_forecast_table" {
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
          service = 'AWS Lambda'
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

# Analysis

query "aws_lambda_function_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "functions"
    from
      aws_lambda_function as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "aws_lambda_function_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_lambda_function as i
    group by
      region;
  EOQ
}

query "aws_lambda_function_by_runtime" {
  sql = <<-EOQ
    select
      runtime,
      count(runtime)
    from
      aws_lambda_function
    group by
      runtime;
  EOQ
}

query "aws_lambda_function_memory_by_region" {
  sql = <<-EOQ
    select region as "Region", sum(memory_size) as "MB" from aws_lambda_function group by region order by region
  EOQ
}

query "aws_lambda_function_code_size_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      round(cast(sum(i.code_size)/1024/1024 as numeric), 1) as "MB"
      --sum(code_size) as "total_Size",
    from
      aws_lambda_function as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "aws_lambda_function_code_size_by_region" {
  sql = <<-EOQ
    select
      region,
      round(cast(sum(i.code_size)/1024/1024 as numeric), 1) as "MB"
    from
      aws_lambda_function as i
    group by
      region;
  EOQ
}

query "aws_lambda_function_code_size_by_runtime" {
  sql = <<-EOQ
    select
      runtime,
      round(cast(sum(i.code_size)/1024/1024 as numeric), 1) as "MB"
    from
      aws_lambda_function as i
    group by
      runtime
  EOQ
}

query "aws_lambda_function_memory_size_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      round(cast(sum(i.memory_size)/1024 as numeric), 1) as "GB"
      --sum(code_size) as "total_Size",
    from
      aws_lambda_function as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "aws_lambda_function_memory_size_by_region" {
  sql = <<-EOQ
    select
      region,
      round(cast(sum(i.memory_size)/1024 as numeric), 1) as "GB"
    from
      aws_lambda_function as i
    group by
      region;
  EOQ
}

query "aws_lambda_function_memory_size_by_runtime" {
  sql = <<-EOQ
    select
      runtime,
      round(cast(sum(i.memory_size)/1024 as numeric), 1) as "GB"
    from
      aws_lambda_function as i
    group by
      runtime;
  EOQ
}

query "aws_lambda_high_error_rate" {
  sql = <<-EOQ
    with error_rates as (
      select
        errors.name as name,
        sum(errors.sum)/sum(invocations.sum)*100 as error_rate
      from
        aws_lambda_function_metric_errors_daily as errors , aws_lambda_function_metric_invocations_daily as invocations
      where
          errors.name = invocations.name
      group by
          errors.name
    )
    select
      name,
      error_rate
    from
      error_rates
    where  error_rate >= 10;
  EOQ
}

query "aws_lambda_function_invocation_rate" {
  sql = <<-EOQ
    with top_n as (
      select
        name,
        avg(average)
      from
        aws_lambda_function_metric_invocations_daily
      where
      timestamp  >= CURRENT_DATE - INTERVAL '365 day'
      group by
        name
      order by
        avg desc
      limit 10
    )
    select
      timestamp,
      name,
      average
    from
      aws_lambda_function_metric_invocations_daily
    where
      timestamp  >= CURRENT_DATE - INTERVAL '365 day'
      and name in (select name from top_n)
    order by
      timestamp;
  EOQ
}

dashboard "aws_lambda_function_dashboard" {

  title = "AWS Lambda Function Dashboard"

  container {

    # Analysis
    card {
      sql   = query.aws_lambda_function_count.sql
      width = 2
    }

    card {
      sql   = query.aws_lambda_function_memory_total.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_lambda_function_public_count.sql
      width = 2
    }

    card {
      sql   = query.aws_lambda_function_unencrypted_count.sql
      width = 2
    }

    card {
      sql   = query.aws_lambda_function_not_in_vpc_count.sql
      width = 2
    }

    # Costs
    card {
      sql   = <<-EOQ
        select
          'Cost - MTD' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_monthly as c
        where
          service = 'AWS Lambda'
          and period_end > date_trunc('month', CURRENT_DATE::timestamp);
      EOQ
      type  = "info"
      icon  = "currency-dollar"
      width = 2
    }

  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Public/Private Status"
      sql   = query.aws_lambda_function_public_status.sql
      type  = "donut"
      width = 4
    }

    chart {
      title = "Encryption Status"
      sql   = query.aws_lambda_function_by_encryption_status.sql
      type  = "donut"
      width = 4
    }

    chart {
      title = "VPC Status"
      sql   = query.aws_lambda_function_vpc_status.sql
      type  = "donut"
      width = 4
    }

    chart {
      title = "Latest Runtime Status"
      sql   = query.aws_lambda_function_use_latest_runtime_status.sql
      type  = "donut"
      width = 4
    }

    chart {
      title = "Dead Letter Config Status"
      sql   = query.aws_lambda_function_dead_letter_config_status.sql
      type  = "donut"
      width = 4
    }

  }

  container {
    title = "Cost"
    width = 6

    # Costs
    table {
      width = 6
      title = "Forecast"
      sql   = query.aws_lambda_monthly_forecast_table.sql
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      sql   = query.aws_lambda_function_cost_per_month.sql
    }

  }

  container {
    title = "Analysis"

    #title = "Counts"
    chart {
      title = "Functions by Account"
      sql   = query.aws_lambda_function_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Functions by Region"
      sql   = query.aws_lambda_function_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Functions by Runtime"
      sql   = query.aws_lambda_function_by_runtime.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Functions Code Size by Account (MB)"
      sql   = query.aws_lambda_function_code_size_by_account.sql
      type  = "column"
      width = 4

      series "MB" {
        color = "tan"
      }
    }

    chart {
      title = "Functions Code Size by Region (MB)"
      sql   = query.aws_lambda_function_code_size_by_region.sql
      type  = "column"
      width = 4

      series "MB" {
        color = "tan"
      }
    }

    chart {
      title = "Functions Code Size by Runtime"
      sql   = query.aws_lambda_function_code_size_by_runtime.sql
      type  = "column"
      width = 4

      series "MB" {
        color = "tan"
      }
    }

    chart {
      title = "Functions Memory Size by Account (GB)"
      sql   = query.aws_lambda_function_memory_size_by_account.sql
      type  = "column"
      width = 4

      series "GB" {
        color = "olive"
      }
    }

    chart {
      title = "Functions Memory Size by Region (GB)"
      sql   = query.aws_lambda_function_memory_size_by_region.sql
      type  = "column"
      width = 4

      series "GB" {
        color = "olive"
      }
    }

    chart {
      title = "Functions Memory Size by Runtime (GB)"
      sql   = query.aws_lambda_function_memory_size_by_runtime.sql
      type  = "column"
      width = 4

      series "GB" {
        color = "olive"
      }
    }

  }

  container {
    title = "Performance & Utilization"
    width = 12

    chart {
      title = "Functions with high error rate (> 10 In Last 1 Month)"
      sql   = query.aws_lambda_high_error_rate.sql
      type  = "line"
      width = 6
    }

    chart {
      title = "Functions Invocation Rate"
      sql   = query.aws_lambda_function_invocation_rate.sql
      type  = "line"
      width = 6
    }

  }

}
