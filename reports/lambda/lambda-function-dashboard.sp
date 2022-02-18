query "aws_lambda_function_count" {
  sql = <<-EOQ
    select count(*) as "Functions" from aws_lambda_function
  EOQ
}

query "aws_public_lambda_function_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
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
      'Not In VPC' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_lambda_function
    where
      vpc_id is null
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
      encryption_status desc
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
      runtime_status desc
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
          dead_letter_config_status desc
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
      vpc_status desc
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
      account
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

#query "aws_lambda_function_cost_by_usage_types_12mo" {
#  sql = <<-EOQ
#    select
#      usage_type,
#      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
#    from
#      aws_cost_by_service_usage_type_monthly
#    where
#      service = 'AWS Lambda'
#      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
#    group by
#      usage_type
#    order by
#      sum(unblended_cost_amount) desc
#  EOQ
#}

#query "aws_lambda_function_cost_by_account_12mo" {
#  sql = <<-EOQ
#    select
#     a.title as "account",
#      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
#    from
#      aws_cost_by_service_monthly as c,
#      aws_account as a
#    where
#      a.account_id = c.account_id
#      and service = 'AWS Lambda'
#      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
#    group by
#      account
#    order by
#      account
#  EOQ
#}

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

#query "aws_lambda_function_cost_top_usage_types_mtd" {
#  sql = <<-EOQ
#    select
#      usage_type,
#      sum(unblended_cost_amount)::numeric as "Unblended Cost"
#    from
#      aws_cost_by_service_usage_type_monthly
#    where
#      service = 'AWS Lambda'
#      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
#    group by
#      period_start,
#      usage_type
#    having
#      round(sum(unblended_cost_amount)::numeric,2) > 0
#    order by
#      sum(unblended_cost_amount) desc
#  EOQ
#}

query "aws_lambda_function_public_status" {
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
      visibility
  EOQ
}

#query "aws_lambda_function_cost_by_account_mtd" {
#  sql = <<-EOQ
#    select
#      a.title as "account",
#      sum(unblended_cost_amount)::numeric as "Unblended Cost"
#    from
#      aws_cost_by_service_monthly as c,
#      aws_account as a
#    where
#      a.account_id = c.account_id
#      and service = 'AWS Lambda'
#      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
#    group by
#      account
#    order by
#      account
#  EOQ
#}

dashboard "aws_lambda_function_dashboard" {

  title = "AWS Lambda Function Dashboard"

  container {

    card {
      sql   = query.aws_lambda_function_count.sql
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
          service = 'AWS Lambda'
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
          service = 'AWS Lambda'
          and date_trunc('month', period_start) = date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
      EOQ
      type = "info"
      icon = "currency-dollar"
      width = 2
    }

    # Assessments

    card {
      sql   = query.aws_public_lambda_function_count.sql
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
      title = "Functions by Runtime"
      sql   = query.aws_lambda_function_by_runtime.sql
      type  = "column"
      width = 3
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Public/Private Status"
      sql   = query.aws_lambda_function_public_status.sql
      type  = "donut"
      width = 3
    }

     chart {
      title = "Encryption Status"
      sql   = query.aws_lambda_function_by_encryption_status.sql
      type  = "donut"
      width = 2

      series "Enabled" {
        color = "green"
      }
    }

    chart {
      title = "VPC Status"
      sql   = query.aws_lambda_function_vpc_status.sql
      type  = "donut"
      width = 2
    }

    chart {
      title = "Latest Runtime Status"
      sql   = query.aws_lambda_function_use_latest_runtime_status.sql
      type  = "donut"
      width = 2
    }

    chart {
      title = "Dead Letter Config Status"
      sql   = query.aws_lambda_function_dead_letter_config_status.sql
      type  = "donut"
      width = 2
    }
  }

  container {
    title = "Costs"
    width = 4

    chart {
      title = "Lambda Monthly Unblended Cost"
      type  = "line"
      sql   = query.aws_lambda_function_cost_per_month.sql
    }

   #chart {
     # title = "Lambda Cost by Usage Type - MTD"
      #type  = "donut"
      #sql   = #query.aws_lambda_function_cost_top_usage_types_mtd.sql
      #width = 2
    #}

   #chart {
      #title = "Lambda Cost by Usage Type - 12 months"
     # type  = "donut"
     # sql   = #query.aws_lambda_function_cost_by_usage_types_12mo.sql
     # width = 2
   # }

   # chart {
     # title = "Lambda Cost by Account - MTD"
     # type  = "donut"
     # sql   = query.aws_lambda_function_cost_by_account_mtd.sql
     #  width = 2
    #}

    #chart {
    #  title = "Lambda Cost By Account - 12 months"
     # type  = "donut"
     # sql   = query.aws_lambda_function_cost_by_account_12mo.sql
    # # width = 2
    #}

  }

  container {
    title  = "Performance & Utilization"
    width = 8

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