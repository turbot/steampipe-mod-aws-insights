dashboard "codebuild_project_dashboard" {

  title         = "AWS CodeBuild Project Dashboard"
  documentation = file("./dashboards/codebuild/docs/codebuild_project_dashboard.md")

  tags = merge(local.codebuild_common_tags, {
    type = "Dashboard"
  })

  #cards

  container {

    card {
      query = query.codebuild_project_count
      width = 2
    }

    #Assessments
    card {
      query = query.codebuild_project_encryption_disabled
      width = 2
    }

    card {
      query = query.codebuild_project_logging_disabled
      width = 2
    }

    card {
      query = query.codebuild_project_privileged_mode_disabled
      width = 2
    }

    card {
      query = query.codebuild_project_badge_disabled
      width = 2
    }

  }

  # Assessments

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      query = query.codebuild_project_encryption_status
      type  = "donut"
      width = 3

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
      title = "Logging Status"
      query = query.codebuild_project_logging_status
      type  = "donut"
      width = 3

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
      title = "Privileged Mode Status"
      query = query.codebuild_project_privileged_mode_status
      type  = "donut"
      width = 3

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
      title = "Badge Status"
      query = query.codebuild_project_badge_status
      type  = "donut"
      width = 3

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
      query = query.codebuild_project_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.codebuild_project_cost_per_month
    }

  }

  # Analysis

  container {

    title = "Analysis"

    chart {
      title = "Projects by Account"
      query = query.codebuild_project_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Projects by Region"
      query = query.codebuild_project_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Projects by Visibility"
      query = query.codebuild_project_by_visibility
      type  = "column"
      width = 4
    }

    chart {
      title = "Projects by Creation Month"
      query = query.codebuild_project_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Projects by Environment Type"
      query = query.codebuild_project_by_environment_type
      type  = "column"
      width = 4
    }

    chart {
      title = "Projects by Source Type"
      query = query.codebuild_project_by_source_type
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "codebuild_project_count" {
  sql = <<-EOQ
    select
      count(*) as "Projects"
    from
      aws_codebuild_project;
  EOQ
}

query "codebuild_project_encryption_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Encryption Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_codebuild_project
    where
      encryption_key is null;
  EOQ
}

query "codebuild_project_logging_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_codebuild_project
    where
      not((logs_config -> 'CloudWatchLogs' ->> 'Status' = 'ENABLED') or (logs_config -> 'S3Logs' ->> 'Status' = 'ENABLED'));
  EOQ
}

query "codebuild_project_privileged_mode_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Privileged Mode Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_codebuild_project
    where
      environment ->> 'PrivilegedMode' = 'false';
  EOQ
}

query "codebuild_project_badge_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Badge Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_codebuild_project
    where
      badge ->> 'BadgeEnabled' = 'false';
  EOQ
}

# Assessment Queries

query "codebuild_project_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select encryption_key,
        case when encryption_key is not null then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_codebuild_project) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "codebuild_project_logging_status" {
  sql = <<-EOQ
    select
      logging_status,
      count(*)
    from (
      select
        logs_config -> 'CloudWatchLogs' ->> 'Status',
        logs_config -> 'S3Logs' ->> 'Status',
        case when (logs_config -> 'CloudWatchLogs' ->> 'Status' = 'ENABLED') or (logs_config -> 'S3Logs' ->> 'Status' = 'ENABLED') then
          'enabled'
        else
          'disabled'
        end logging_status
      from
        aws_codebuild_project) as t
    group by
      logging_status
    order by
      logging_status desc;
  EOQ
}

query "codebuild_project_privileged_mode_status" {
  sql = <<-EOQ
    select
      privileged_mode,
      count(*)
    from (
      select environment ->> 'PrivilegedMode',
        case when environment ->> 'PrivilegedMode' = 'true' then
          'enabled'
        else
          'disabled'
        end privileged_mode
      from
        aws_codebuild_project) as t
    group by
      privileged_mode
    order by
      privileged_mode desc;
  EOQ
}

query "codebuild_project_badge_status" {
  sql = <<-EOQ
    select
      badge_status,
      count(*)
    from (
      select badge ->> 'BadgeEnabled',
        case when badge ->> 'BadgeEnabled' = 'true' then
          'enabled'
        else
          'disabled'
        end badge_status
      from
        aws_codebuild_project) as t
    group by
      badge_status
    order by
      badge_status desc;
  EOQ
}

// # Cost Queries

query "codebuild_project_forecast_table" {
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
        service = 'CodeBuild'
        and usage_type like '%Build%'
        -- and date_trunc('month', period_start) >= date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
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

query "codebuild_project_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'CodeBuild'
      and usage_type like '%Build%'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "codebuild_project_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(p.*) as "projects"
    from
      aws_codebuild_project as p,
      aws_account as a
    where
      a.account_id = p.account_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "codebuild_project_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "projects"
    from
      aws_codebuild_project
    group by
      region
    order by
      region;
  EOQ
}

query "codebuild_project_by_visibility" {
  sql = <<-EOQ
    select
      project_visibility as "Visibility",
      count(*) as "projects"
    from
      aws_codebuild_project
    group by
      project_visibility
    order by
      project_visibility;
  EOQ
}

query "codebuild_project_by_environment_type" {
  sql = <<-EOQ
    select
      environment->'Type' as "Environment Type",
      count(*) as "projects"
    from
      aws_codebuild_project
    group by
      environment->'Type'
    order by
      environment->'Type';
  EOQ
}

query "codebuild_project_by_source_type" {
  sql = <<-EOQ
    select
      source->'Type' as "Source Type",
      count(*) as "projects"
    from
      aws_codebuild_project
    group by
      source->'Type'
    order by
      source->'Type';
  EOQ
}

query "codebuild_project_by_creation_month" {
  sql = <<-EOQ
    with clusters as (
      select
        title,
        created ,
        to_char(created ,
          'YYYY-MM') as creation_month
      from
        aws_codebuild_project
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created )
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
