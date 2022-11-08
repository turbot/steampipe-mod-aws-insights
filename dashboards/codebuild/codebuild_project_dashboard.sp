dashboard "aws_codebuild_project_dashboard" {

  title         = "AWS CodeBuild Project Dashboard"
  documentation = file("./dashboards/codebuild/docs/codebuild_project_dashboard.md")

  tags = merge(local.codebuild_common_tags, {
    type = "Dashboard"
  })

  #cards

  container {

    card {
      sql   = query.aws_codebuild_project_count.sql
      width = 2
    }

    #Assessments
    card {
      sql   = query.aws_codebuild_project_encryption_disabled.sql
      width = 2
    }

    card {
      sql   = query.aws_codebuild_project_logging_disabled.sql
      width = 2
    }

    card {
      sql   = query.aws_codebuild_project_privileged_mode_disabled.sql
      width = 2
    }

    card {
      sql   = query.aws_codebuild_project_badge_disabled.sql
      width = 2
    }

  }

  # Assessments

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      sql   = query.aws_codebuild_project_encryption_status.sql
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
      sql   = query.aws_codebuild_project_logging_status.sql
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
      sql   = query.aws_codebuild_project_privileged_mode_status.sql
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
      sql   = query.aws_codebuild_project_badge_status.sql
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

    chart {
      width = 4
      type  = "column"
      title = "Monthly Cost - 12 Months"
      sql   = query.aws_codebuild_project_cost_per_month.sql
    }

  }

  # Analysis

  container {

    title = "Analysis"

    chart {
      title = "Projects by Account"
      sql   = query.aws_codebuild_project_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Projects by Region"
      sql   = query.aws_codebuild_project_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Projects by Visibility"
      sql   = query.aws_codebuild_project_by_visibility.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Projects by Creation Month"
      sql   = query.aws_codebuild_project_by_creation_month.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Projects by Environment Type"
      sql   = query.aws_codebuild_project_by_environment_type.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Projects by Source Type"
      sql   = query.aws_codebuild_project_by_source_type.sql
      type  = "column"
      width = 4
    }

  }

}


# Card Queries

query "aws_codebuild_project_count" {
  sql = <<-EOQ
    select
      count(*) as "Projects"
    from
      aws_codebuild_project;
  EOQ
}

query "aws_codebuild_project_encryption_disabled" {
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

query "aws_codebuild_project_logging_disabled" {
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

query "aws_codebuild_project_privileged_mode_disabled" {
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

query "aws_codebuild_project_badge_disabled" {
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

// # Assessment Queries

query "aws_codebuild_project_encryption_status" {
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

query "aws_codebuild_project_logging_status" {
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

query "aws_codebuild_project_privileged_mode_status" {
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

query "aws_codebuild_project_badge_status" {
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

query "aws_codebuild_project_cost_per_month" {
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

query "aws_codebuild_project_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(p.*) as "projects"
    from
      aws_codebuild_project as p,
      aws_account as a
    where
      a.account_id = p.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "aws_codebuild_project_by_region" {
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

query "aws_codebuild_project_by_visibility" {
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

query "aws_codebuild_project_by_environment_type" {
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

query "aws_codebuild_project_by_source_type" {
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

query "aws_codebuild_project_by_creation_month" {
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