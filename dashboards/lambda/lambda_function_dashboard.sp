dashboard "lambda_function_dashboard" {

  title         = "AWS Lambda Function Dashboard"
  documentation = file("./dashboards/lambda/docs/lambda_function_dashboard.md")

  tags = merge(local.lambda_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.lambda_function_count
      width = 2
    }

    # Assessments
    card {
      query = query.lambda_function_unencrypted_count
      width = 2
      href  = dashboard.lambda_function_encryption_report.url_path
    }

    card {
      query = query.lambda_function_public_count
      width = 2
      href  = dashboard.lambda_function_public_access_report.url_path
    }

    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      query = query.lambda_function_cost_mtd
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      query = query.lambda_function_by_encryption_status
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
      title = "Public/Private Status"
      query = query.lambda_function_public_status
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
      title = "Runtime Version"
      query = query.lambda_function_uses_latest_runtime_status
      type  = "donut"
      width = 4

      series "count" {
        point "latest" {
          color = "ok"
        }
        point "previous" {
          color = "alert"
        }
      }
    }

    chart {
      title = "DLQ Configuration"
      query = query.lambda_function_dead_letter_config_status
      type  = "donut"
      width = 4

      series "count" {
        point "configured" {
          color = "ok"
        }
        point "not configured" {
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
      query = query.lambda_monthly_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.lambda_function_cost_per_month
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Functions by Account"
      query = query.lambda_function_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Functions by Region"
      query = query.lambda_function_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Functions by Runtime"
      query = query.lambda_function_by_runtime
      type  = "column"
      width = 4
    }

    chart {
      title = "Function Code Size by Account (MB)"
      query = query.lambda_function_code_size_by_account
      type  = "column"
      width = 4

      series "MB" {
        color = "tan"
      }
    }

    chart {
      title = "Function Code Size by Region (MB)"
      query = query.lambda_function_code_size_by_region
      type  = "column"
      width = 4

      series "MB" {
        color = "tan"
      }
    }

    chart {
      title = "Function Code Size by Runtime (MB)"
      query = query.lambda_function_code_size_by_runtime
      type  = "column"
      width = 4

      series "MB" {
        color = "tan"
      }
    }

    chart {
      title = "Function Memory Usage by Account (GB)"
      query = query.lambda_function_memory_size_by_account
      type  = "column"
      width = 4

      series "GB" {
        color = "olive"
      }
    }

    chart {
      title = "Function Memory Usage by Region (GB)"
      query = query.lambda_function_memory_size_by_region
      type  = "column"
      width = 4

      series "GB" {
        color = "olive"
      }
    }

    chart {
      title = "Function Memory Usage by Runtime (GB)"
      query = query.lambda_function_memory_size_by_runtime
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
      title = "High Error Rate (> 10 In Last 1 Month)"
      query = query.lambda_high_error_rate
      type  = "line"
      width = 6
    }

    chart {
      title = "Top 10 Average Invocation Rate"
      query = query.lambda_function_invocation_rate
      type  = "line"
      width = 6
    }

  }

}

# Card Queries

query "lambda_function_count" {
  sql = <<-EOQ
    select count(*) as "Functions" from aws_lambda_function
  EOQ
}

query "lambda_function_unencrypted_count" {
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

query "lambda_function_public_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Publicly Accessible' as label,
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

query "lambda_function_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_monthly as c
    where
      service = 'AWS Lambda'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp);
  EOQ
}

# Assessment Queries

query "lambda_function_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select
        case when kms_key_arn is not null then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_lambda_function) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "lambda_function_public_status" {
  sql = <<-EOQ
    with functions as (
      select
        case
          when
          policy_std -> 'Statement' ->> 'Effect' = 'Allow'
          and ( policy_std -> 'Statement' ->> 'Prinipal' = '*'
          or ( policy_std -> 'Principal' -> 'AWS' ) :: text = '*'
        ) then 'public'
          else 'private'
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

query "lambda_function_uses_latest_runtime_status" {
  sql = <<-EOQ
    select
      runtime_status,
      count(*)
    from (
      select
        case when runtime not in ('nodejs14.x', 'nodejs12.x', 'nodejs10.x', 'python3.8', 'python3.7', 'python3.6', 'ruby2.5', 'ruby2.7', 'java11', 'java8', 'go1.x', 'dotnetcore2.1', 'dotnetcore3.1') then
          'previous'
        else
          'latest'
        end runtime_status
      from
        aws_lambda_function) as t
    group by
      runtime_status
    order by
      runtime_status desc;
  EOQ
}

query "lambda_function_dead_letter_config_status" {
  sql = <<-EOQ
    select
      dead_letter_config_status,
      count(*)
    from (
      select
        case when dead_letter_config_target_arn is not null then
          'configured'
        else
          'not configured'
        end dead_letter_config_status
      from
        aws_lambda_function) as t
      group by
        dead_letter_config_status
      order by
        dead_letter_config_status desc;
  EOQ
}

# Cost Queries

query "lambda_monthly_forecast_table" {
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

query "lambda_function_cost_per_month" {
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

# Analysis Queries

query "lambda_function_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
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

query "lambda_function_by_region" {
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

query "lambda_function_by_runtime" {
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

query "lambda_function_code_size_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      round(cast(sum(i.code_size)/1024/1024 as numeric), 1) as "MB"
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

query "lambda_function_code_size_by_region" {
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

query "lambda_function_code_size_by_runtime" {
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

query "lambda_function_memory_size_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      round(cast(sum(i.memory_size)/1024.0 as numeric), 2) as "GB"
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

query "lambda_function_memory_size_by_region" {
  sql = <<-EOQ
    select
      region,
      round(cast(sum(i.memory_size)/1024.0 as numeric), 2) as "GB"
    from
      aws_lambda_function as i
    group by
      region;
  EOQ
}

query "lambda_function_memory_size_by_runtime" {
  sql = <<-EOQ
    select
      runtime,
      round(cast(sum(i.memory_size)/1024.0 as numeric), 2) as "GB"
    from
      aws_lambda_function as i
    group by
      runtime;
  EOQ
}

# Performance Queries

query "lambda_high_error_rate" {
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

query "lambda_function_invocation_rate" {
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
