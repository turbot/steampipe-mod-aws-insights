dashboard "s3_bucket_dashboard" {

  title         = "AWS S3 Bucket Dashboard"
  documentation = file("./dashboards/s3/docs/s3_bucket_dashboard.md")

  tags = merge(local.s3_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.s3_bucket_count
      width = 2
    }

    # Assessments
    card {
      query = query.s3_bucket_public_block_count
      width = 2
      href  = dashboard.s3_bucket_public_access_report.url_path
    }

    card {
      query = query.s3_bucket_unencrypted_count
      width = 2
      href  = dashboard.s3_bucket_encryption_report.url_path
    }

    card {
      query = query.s3_bucket_logging_disabled_count
      width = 2
      href  = dashboard.s3_bucket_logging_report.url_path
    }

    card {
      query = query.s3_bucket_versioning_disabled_count
      width = 2
      href  = dashboard.s3_bucket_lifecycle_report.url_path
    }

    # Costs
    card {
      query = query.s3_bucket_cost_mtd
      type  = "info"
      icon  = "currency-dollar"
      width = 2
    }
  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Public Access Blocked"
      query = query.s3_bucket_public_access_blocked
      type  = "donut"
      width = 4

      series "count" {
        point "blocked" {
          color = "ok"
        }
        point "not blocked" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Default Encryption Status"
      query = query.s3_bucket_by_default_encryption_status
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
      title = "Logging Status"
      query = query.s3_bucket_logging_status
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
      title = "Versioning Status"
      query = query.s3_bucket_versioning_status
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
      title = "Versioning MFA Status"
      query = query.s3_bucket_versioning_mfa_status
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
      title = "Cross-Region Replication"
      query = query.s3_bucket_cross_region_replication_status
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

  }

  container {
    title = "Cost"
    width = 6

    table {
      width = 6
      title = "Forecast"
      query = query.s3_monthly_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.s3_bucket_cost_per_month
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Buckets by Account"
      query = query.s3_bucket_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Buckets by Region"
      query = query.s3_bucket_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Buckets by Age"
      query = query.s3_bucket_by_creation_month
      type  = "column"
      width = 4
    }

  }

}


# Card Queries

query "s3_bucket_count" {
  sql = <<-EOQ
    select count(*) as "Buckets" from aws_s3_bucket;
  EOQ
}

query "s3_bucket_versioning_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Versioning Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      not versioning_enabled;
  EOQ
}

query "s3_bucket_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      server_side_encryption_configuration is null;
  EOQ
}

query "s3_bucket_public_block_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Access Not Blocked' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      not block_public_acls
      or not block_public_policy
      or not ignore_public_acls
      or not restrict_public_buckets;
  EOQ
}

query "s3_bucket_logging_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      logging -> 'TargetBucket' is null;
  EOQ
}

query "s3_bucket_cost_mtd" {
  sql = <<-EOQ
        select
          'Cost - MTD' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_monthly
        where
          service = 'Amazon Simple Storage Service'
          and period_end > date_trunc('month', CURRENT_DATE::timestamp)
      EOQ
}

# Assessment Queries

query "s3_bucket_versioning_status" {
  sql = <<-EOQ
    with versioning_status as (
      select
        case
          when versioning_enabled then 'enabled' else 'disabled'
        end as visibility
      from
        aws_s3_bucket
    )
    select
      visibility,
      count(*)
    from
      versioning_status
    group by
      visibility;
  EOQ
}

query "s3_bucket_by_default_encryption_status" {
  sql = <<-EOQ
    with default_encryption as (
      select
        case when server_side_encryption_configuration is not null then 'enabled' else 'disabled'
        end as visibility
      from
        aws_s3_bucket
    )
    select
      visibility,
      count(*)
    from
      default_encryption
    group by
      visibility;
  EOQ
}

query "s3_bucket_public_access_blocked" {
  sql = <<-EOQ
    with public_block_status as (
      select
        case
          when
            block_public_acls
            and block_public_policy
            and ignore_public_acls
            and restrict_public_buckets
          then 'blocked' else 'not blocked'
        end as block_status
      from
        aws_s3_bucket
    )
    select
      block_status,
      count(*)
    from
      public_block_status
    group by
      block_status;
  EOQ
}

query "s3_bucket_logging_status" {
  sql = <<-EOQ
    with logging_status as (
      select
        case when logging -> 'TargetBucket' is not null then 'enabled' else 'disabled'
        end as visibility
      from
        aws_s3_bucket
    )
    select
      visibility,
      count(*)
    from
      logging_status
    group by
      visibility;
      EOQ
}

query "s3_bucket_versioning_mfa_status" {
  sql = <<-EOQ
    with versioning_mfa_status as (
      select
        case
          when versioning_mfa_delete then 'enabled' else 'disabled'
        end as visibility
      from
        aws_s3_bucket
    )
    select
      visibility,
      count(*)
    from
      versioning_mfa_status
    group by
      visibility;
  EOQ
}

query "s3_bucket_cross_region_replication_status" {
  sql = <<-EOQ
    with bucket_with_replication as (
          select
            name,
            r ->> 'Status' as rep_status
          from
            aws_s3_bucket,
            jsonb_array_elements(replication -> 'Rules' ) as r
        ), tets as (
            select
              case
                when b.name = r.name and r.rep_status = 'Enabled' then 'enabled' else 'disabled'
              end as visibility
            from
              aws_s3_bucket b
              left join bucket_with_replication r on b.name = r.name
          )
          select
            visibility,
            count(*)
          from
            tets
          group by
            visibility;
      EOQ
}

# Cost Queries

query "s3_monthly_forecast_table" {
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
        service = 'Amazon Simple Storage Service'
        and date_trunc('month', period_start) >= date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
        group by
          period_start, period_end
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

query "s3_bucket_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount)::numeric as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Simple Storage Service'
    group by
      period_start
    order by
      period_start;
  EOQ
}

# Analysis Queries

query "s3_bucket_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(i.*) as "total"
    from
      aws_s3_bucket as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      a.title
    order by 
      count(i.*) desc;
  EOQ
}

query "s3_bucket_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_s3_bucket as i
    group by
      region;
  EOQ
}

query "s3_bucket_by_creation_month" {
  sql = <<-EOQ
    with s3_buckets as (
      select
        title,
        creation_date,
        to_char(creation_date,
          'YYYY-MM') as creation_month
      from
        aws_s3_bucket
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
                from s3_buckets)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    buckets_by_month as (
      select
        creation_month,
        count(*)
      from
        s3_buckets
      group by
        creation_month
    )
    select
      months.month,
      buckets_by_month.count
    from
      months
      left join buckets_by_month on months.month = buckets_by_month.creation_month
    order by
      months.month;
  EOQ
}
