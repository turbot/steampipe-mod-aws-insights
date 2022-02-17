query "aws_lambda_function_count" {
  sql = <<-EOQ
    select count(*) as "Functions" from aws_lambda_function
  EOQ
}

query "aws_public_lambda_function_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Functions' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_lambda_function
    where
      policy_std -> 'Statement' ->> 'Effect' = 'Allow'
    and (
      policy_std -> 'Statement' ->> 'Prinipal' = '*'
      or ( policy_std -> 'Principal' -> 'AWS' ) :: text = '*'
    )
  EOQ
}

query "aws_lambda_function_not_in_vpc_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Functions Not In VPC' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_lambda_function
    where
      vpc_id is null
  EOQ
}

query "aws_lambda_function_use_latest_runtime" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Functions Not Using Latest Runtime' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_lambda_function
    where
      runtime not in ('nodejs14.x', 'nodejs12.x', 'nodejs10.x', 'python3.8', 'python3.7', 'python3.6', 'ruby2.5', 'ruby2.7', 'java11', 'java8', 'go1.x', 'dotnetcore2.1', 'dotnetcore3.1')
  EOQ
}

query "aws_lambda_function_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'AWS Lambda'
    group by
      period_start
    order by
      period_start
  EOQ
}

query "aws_lambda_function_cost_last_30_counter" {
  sql = <<-EOQ
    select
       'Cost - Last 30 Days' as label,
       sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_daily
    where
      service = 'AWS Lambda'
      and period_start  >=  CURRENT_DATE - INTERVAL '30 day'
  EOQ
}

query "aws_lambda_function_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_lambda_function as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc

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
      region
  EOQ
}

query "aws_lambda_function_by_state" {
  sql = <<-EOQ
    select
      state,
      count(state)
    from
      aws_lambda_function
    group by
      state
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
      runtime
  EOQ
}

query "aws_lambda_function_dead_letter_queue_status" {
  sql = <<-EOQ
    with functions as (
      select
        case
          when dead_letter_config_target_arn is not null then 'enabled'
          else 'disabled'
        end as dead_letter
      from
        aws_lambda_function
    )
    select
      dead_letter,
      count(*)
    from
      functions
    group by
      dead_letter
  EOQ
}

query "aws_lambda_function_concurrent_execution_limit_status" {
  sql = <<-EOQ
    with functions as (
      select
        case
          when reserved_concurrent_executions is not null then 'enabled'
          else 'disabled'
        end as reserved_concurrent_executions
      from
        aws_lambda_function
    )
    select
      reserved_concurrent_executions,
      count(*)
    from
      functions
    group by
      reserved_concurrent_executions
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
    where  error_rate >= 10
  EOQ
}

query "aws_lambda_function_cost_by_usage_types_30day" {
  sql = <<-EOQ
    select
      usage_type,
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_daily
    where
      service = 'AWS Lambda'
      --and period_end >= date_trunc('month', CURRENT_DATE::timestamp)
      and period_end >=  CURRENT_DATE - INTERVAL '30 day'
    group by
      usage_type
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_lambda_function_cost_by_usage_types_12mo" {
  sql = <<-EOQ
    select
      usage_type,
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'AWS Lambda'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      usage_type
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_lambda_function_cost_by_account_30day" {
  sql = <<-EOQ
    select
      a.title as "account",
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'AWS Lambda'
     and period_end >=  CURRENT_DATE - INTERVAL '30 day'
    group by
      account
    order by
      account
  EOQ
}

query "aws_lambda_function_cost_by_account_12mo" {
  sql = <<-EOQ
    select
      a.title as "account",
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'AWS Lambda'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      account
    order by
      account
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
      timestamp
  EOQ
}

dashboard "aws_lambda_function_dashboard" {

  title = "AWS Lambda Function Dashboard"

  container {

    card {
      sql   = query.aws_lambda_function_count.sql
      width = 2
    }

    card {
      sql   = query.aws_public_lambda_function_count.sql
      width = 2
    }

    card {
      sql   = query.aws_lambda_function_not_in_vpc_count.sql
      width = 2
    }

    card {
      sql   = query.aws_lambda_function_use_latest_runtime.sql
      width = 2
    }

    card {
      sql   = query.aws_lambda_function_cost_last_30_counter.sql
      width = 2
    }

    card {
      sql   = query.aws_lambda_function_cost_per_month.sql
      width = 2
    }

  }

  container {
    title = "Analysis"

    #title = "Counts"
    chart {
      title = "Functions by Account"
      sql   = query.aws_lambda_function_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Functions by Region"
      sql   = query.aws_lambda_function_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Functions by State"
      sql   = query.aws_lambda_function_by_state.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Functions by Runtime"
      sql   = query.aws_lambda_function_by_runtime.sql
      type  = "column"
      width = 3
    }

  }

  container {
    title = "Assessments"

    table {
      title = "Dead Letter Config Status"
      width = 6
      sql = <<-EOQ
        select
          name as "function",
          case when dead_letter_config_target_arn is not null then 'Enabled' else 'Disabled' end as "Dead Letter Config ",
          account_id as "Account",
          region as "Region",
          arn as "ARN"
        from
          aws_lambda_function
      EOQ
    }

    table {
      title = "Concurrent Execution Status"
      width = 6
      sql = <<-EOQ
        select
          name as "function",
          case when reserved_concurrent_executions is not null then 'Enabled' else 'Disabled' end as "Concurrent Execution",
          account_id as "Account",
          region as "Region",
          arn as "ARN"
        from
          aws_lambda_function
      EOQ
    }
  }

  container {
    title = "Costs"

    chart {
      title = "Lambda Monthly Cost"
      type  = "line"
      sql   = query.aws_lambda_function_cost_per_month.sql
      width = 4
    }


   chart {
      title = "Lambda Cost by Usage Type - last 30 days"
      type  = "donut"
      sql   = query.aws_lambda_function_cost_by_usage_types_30day.sql
      width = 2
    }

   chart {
      title = "Lambda Cost by Usage Type - Last 12 months"
      type  = "donut"
      sql   = query.aws_lambda_function_cost_by_usage_types_12mo.sql
      width = 2
    }


    chart {
      title = "By Account - MTD"
      type  = "donut"
      sql   = query.aws_lambda_function_cost_by_account_30day.sql
       width = 2
    }

    chart {
      title = "By Account - Last 12 months"
      type  = "donut"
      sql   = query.aws_lambda_function_cost_by_account_12mo.sql
      width = 2
    }

  }

  container {
    title  = "Performance & Utilization"

    chart {
      title = "Functions with high error rate (> 10 In Last 1 Month)"
      sql   = query.aws_lambda_high_error_rate.sql
      type  = "line"
      width = 6
    }
  }

  container {

    chart {
      title = "Functions Invocation Rate"
      sql   = query.aws_lambda_function_invocation_rate.sql
      type  = "line"
      width = 6
    }
  }
}