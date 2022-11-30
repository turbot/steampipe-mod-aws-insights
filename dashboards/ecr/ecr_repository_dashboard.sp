dashboard "ecr_repository_dashboard" {

  title         = "AWS ECR Repository Dashboard"
  documentation = file("./dashboards/ecr/docs/ecr_repository_dashboard.md")

  tags = merge(local.ecr_common_tags, {
    type = "Dashboard"
  })

  #cards

  container {

    card {
      query   = query.ecr_repository_count
      width = 2
    }

    #Assessments
    card {
      query   = query.ecr_repository_encryption_disabled_count
      width = 2
    }

    card {
      query   = query.ecr_repository_scan_on_push_disabled_count
      width = 2
    }

    card {
      query   = query.ecr_repository_tagging_disabled_count
      width = 2
    }

    card {
      query   = query.ecr_repository_tag_mutability_count
      width = 2
    }

  }

  # Assessments

  container {

    title = "Assessments"
    
    chart {
      title = "Encryption Status"
      query   = query.ecr_repository_encryption_status
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
      title = "Scan on Push Status"
      query   = query.ecr_repository_scan_on_push_status
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
      title = "Untagged"
      query   = query.ecr_repository_tagging_status
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
      title = "Tag Immutability Status"
      query   = query.ecr_repository_tag_immutability_status
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

  # Analysis

  container {

    title = "Analysis"

    chart {
      title = "ECR Repositories by Account"
      query   = query.ecr_repository_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "ECR Repositories by Region"
      query   = query.ecr_repository_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "ECR Repositories by Creation Month"
      query   = query.ecr_repository_by_creation_month
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "ecr_repository_count" {
  sql = <<-EOQ
    select
      count(*) as "Repositories"
    from
      aws_ecr_repository;
  EOQ
}

query "ecr_repository_encryption_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Encryption Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ecr_repository
    where
      encryption_configuration is null;
  EOQ
}

query "ecr_repository_scan_on_push_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Scan on Push Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ecr_repository
    where
      not (image_scanning_configuration ->> 'ScanOnPush')::bool;
  EOQ
}

query "ecr_repository_tagging_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Untagged' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ecr_repository
    where
      tags = '{}' or tags is null;
  EOQ
}

query "ecr_repository_tag_mutability_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Tag Mutability' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ecr_repository
    where
      image_tag_mutability = 'MUTABLE';
  EOQ
}

// # Assessment Queries

query "ecr_repository_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select 
        encryption_configuration,
        case when encryption_configuration is not null then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_ecr_repository) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "ecr_repository_scan_on_push_status" {
  sql = <<-EOQ
    select
      push_status,
      count(*)
    from (
      select
        (image_scanning_configuration ->> 'ScanOnPush')::bool,
        case when (image_scanning_configuration ->> 'ScanOnPush')::bool then
          'enabled'
        else
          'disabled'
        end push_status
      from
        aws_ecr_repository) as t
    group by
      push_status
    order by
      push_status desc;
  EOQ
}

query "ecr_repository_tagging_status" {
  sql = <<-EOQ
    select
      tag_status,
      count(*)
    from (
      select tags = '{}' or tags is null,
        case when tags = '{}' or tags is null then
          'disabled'
        else
          'enabled'
        end tag_status
      from
        aws_ecr_repository) as t
    group by
      tag_status
    order by
      tag_status desc;
  EOQ
}

query "ecr_repository_tag_immutability_status" {
  sql = <<-EOQ
    select
      tag_mutability_status,
      count(*)
    from (
      select image_tag_mutability = 'IMMUTABLE',
        case when image_tag_mutability = 'IMMUTABLE' then
          'enabled'
        else
          'disabled'
        end tag_mutability_status
      from
        aws_ecr_repository) as t
    group by
      tag_mutability_status
    order by
      tag_mutability_status desc;
  EOQ
}

// # Cost Queries

// query "ecr_repository_forecast_table" {
//   sql = <<-EOQ
//     with monthly_costs as (
//       select
//         period_start,
//         period_end,
//         case
//           when date_trunc('month', period_start) = date_trunc('month', CURRENT_DATE::timestamp) then 'Month to Date'
//           when date_trunc('month', period_start) = date_trunc('month', CURRENT_DATE::timestamp - interval '1 month') then 'Previous Month'
//           else to_char (period_start, 'Month')
//         end as period_label,
//         period_end::date - period_start::date as days,
//         sum(unblended_cost_amount)::numeric::money as unblended_cost_amount,
//         (sum(unblended_cost_amount) / (period_end::date - period_start::date ) )::numeric::money as average_daily_cost,
//         date_part('days', date_trunc ('month', period_start) + '1 MONTH'::interval  - '1 DAY'::interval ) as days_in_month,
//         sum(unblended_cost_amount) / (period_end::date - period_start::date ) * date_part('days', date_trunc ('month', period_start) + '1 MONTH'::interval  - '1 DAY'::interval )::numeric::money  as forecast_amount
//       from
//         aws_cost_by_service_usage_type_monthly as c
//       where
//         service = 'CodeBuild'
//         and usage_type like '%Build%'
//         -- and date_trunc('month', period_start) >= date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
//       group by
//         period_start,
//         period_end
//     )
//     select
//       period_label as "Period",
//       unblended_cost_amount as "Cost",
//       average_daily_cost as "Daily Avg Cost"
//     from
//       monthly_costs
//     union all
//     select
//       'This Month (Forecast)' as "Period",
//       (select forecast_amount from monthly_costs where period_label = 'Month to Date') as "Cost",
//       (select average_daily_cost from monthly_costs where period_label = 'Month to Date') as "Daily Avg Cost";
//   EOQ
// }

// query "ecr_repository_cost_per_month" {
//   sql = <<-EOQ
//     select
//       to_char(period_start, 'Mon-YY') as "Month",
//       sum(unblended_cost_amount) as "Unblended Cost"
//     from
//       aws_cost_by_service_usage_type_monthly
//     where
//       service = 'CodeBuild'
//       and usage_type like '%Build%'
//     group by
//       period_start
//     order by
//       period_start;
//   EOQ
// }

# Analysis Queries

query "ecr_repository_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(p.*) as "ecr repositories"
    from
      aws_ecr_repository as p,
      aws_account as a
    where
      a.account_id = p.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "ecr_repository_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "ecr repositories"
    from
      aws_ecr_repository
    group by
      region
    order by
      region;
  EOQ
}

query "ecr_repository_by_creation_month" {
  sql = <<-EOQ
    with ecr_repositories as (
      select
        title,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        aws_ecr_repository
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_at)
                from ecr_repositories)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    ecr_repositories_by_month as (
      select
        creation_month,
        count(*)
      from
        ecr_repositories
      group by
        creation_month
    )
    select
      months.month,
      ecr_repositories_by_month.count
    from
      months
      left join ecr_repositories_by_month on months.month = ecr_repositories_by_month.creation_month
    order by
      months.month;
  EOQ
}