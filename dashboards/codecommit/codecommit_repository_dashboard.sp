dashboard "aws_codecommit_repository_dashboard" {

  title         = "AWS Codecommit Dashboard"
  documentation = file("./dashboards/codecommit/docs/codecommit_repository_dashboard.md")

  tags = merge(local.codecommit_common_tags, {
    type = "Dashboard"
  })

  # Top cards
  container {

    # Analysis
    card {
      query = query.aws_codecommit_repository_count
      width = 2
    }

    # Assessments
    card {
      query = query.aws_codecommit_repository_untagged_count
      width = 2
    }
    # Costs
    card {
      type  = "info"
      icon  = "currency-dollar"
      width = 2
      query = query.aws_codecommit_repository_cost_mtd
    }
  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Untagged Repository Status"
      type  = "donut"
      width = 4
      query = query.aws_codecommit_repository_untagged_count_status

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
    title = "Costs"
    width = 6

    table {
      width = 6
      title = "Forecast"
      query = query.aws_codecommit_repository_monthly_forecast_table
    }

    chart {
      width = 4
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.aws_codecommit_repository_cost_per_month
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Tables by Account"
      type  = "column"
      width = 3
      query   = query.aws_codecommit_repository_by_account
    }

    chart {
      title = "Tables by Region"
      type  = "column"
      width = 3
      query  = query.aws_codecommit_repository_by_region
    }

    chart {
      title = "Tables by Age"
      query   = query.aws_codecommit_repository_by_creation_month
      type  = "column"
      width = 3
    }

    chart {
      title = "Tables by Partition"
      query   = query.aws_codecommit_repository_by_partition
      type  = "column"
      width = 3
    }
  }

}

# Card Queries

query "aws_codecommit_repository_count" {
  sql = <<-EOQ
    select count(*) as "Tables" from aws_codecommit_repository;
  EOQ
}

query "aws_codecommit_repository_untagged_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Untagged' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_codecommit_repository
    where
      tags = '{}' or tags is null;
  EOQ
}

query "aws_codecommit_repository_cost_mtd" {
  sql = <<-EOQ
    select
      'Cost - MTD' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_usage_type_monthly as c
    where
      service = 'AWS CodeCommit';
  EOQ
}

# Assessment Queries

query "aws_codecommit_repository_untagged_count_status" {
  sql = <<-EOQ
    select
      case
        when tags = '{}' or tags is null then 'disabled'
        else 'enabled'
      end as status,
      count(*)
    from
      aws_codecommit_repository
    group by status;
  EOQ
}

# Cost Queries

query "aws_codecommit_repository_monthly_forecast_table" {
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
        service = 'AWS CodeCommit'
        and usage_type like '%User-Month%'
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

query "aws_codecommit_repository_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'AWS CodeCommit'
      and usage_type like '%User-Month%'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "aws_codecommit_repository_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(t.*) as "repositories"
    from
      aws_codecommit_repository as t,
      aws_account as a
    where
      a.account_id = t.account_id
    group by account
    order by account;
  EOQ
}

query "aws_codecommit_repository_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "tables"
    from
      aws_codecommit_repository
    group by region
    order by region;
  EOQ
}

query "aws_codecommit_repository_by_partition" {
  sql = <<-EOQ
    select
      partition as "Partition",
      count(*) as "tables"
    from
      aws_codecommit_repository
    group by partition
    order by partition;
  EOQ
}

query "aws_codecommit_repository_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        creation_date,
        to_char(creation_date,
          'YYYY-MM') as creation_month
      from
        aws_codecommit_repository
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
          (
            select
              min(creation_date)
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
