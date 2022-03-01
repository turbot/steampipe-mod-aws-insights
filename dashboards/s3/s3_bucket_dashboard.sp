query "aws_s3_bucket_count" {
  sql = <<-EOQ
    select count(*) as "Buckets" from aws_s3_bucket;
  EOQ
}

query "aws_s3_bucket_public_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      not block_public_acls
      or not block_public_policy
      or not ignore_public_acls
      or not restrict_public_buckets
      -- bucket_policy_is_publicy if true then bucket is public
      or bucket_policy_is_public;
  EOQ
}


#Assessments
query "aws_s3_bucket_versioning_status" {
  sql = <<-EOQ
    with versioning_status as(
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

query "aws_s3_bucket_cross_region_replication_status" {
  sql = <<-EOQ
    with bucket_with_replication as (
          select
            name,
            r ->> 'Status' as rep_status
          from
            aws_s3_bucket,
            jsonb_array_elements(replication -> 'Rules' ) as r
        ), tets as(
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

query "aws_s3_bucket_public_status" {
  sql = <<-EOQ
    with public_status as(
      select
        case
          when
            block_public_acls
            and block_public_policy
            and ignore_public_acls
            and restrict_public_buckets
          then 'private' else 'public'
        end as visibility
      from
        aws_s3_bucket
    )
    select
      visibility,
      count(*)
    from
      public_status
    group by
      visibility;
  EOQ
}

query "aws_s3_bucket_versioning_mfa_status" {
  sql = <<-EOQ
    with versioning_mfa_status as(
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

query "aws_s3_bucket_logging_status" {
  sql = <<-EOQ
    with logging_status as(
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

#Costs
query "aws_s3_monthly_forecast_table" {
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

query "aws_s3_bucket_cost_per_month" {
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

query "aws_s3_bucket_by_default_encryption_status" {
  sql = <<-EOQ
    with default_encryption as(
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

#Analysis
query "aws_s3_bucket_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_s3_bucket as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc;
  EOQ
}

query "aws_s3_bucket_by_region" {
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

query "aws_s3_bucket_by_creation_month" {
  sql = <<-EOQ
    with buckets as (
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
                from buckets)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    buckets_by_month as (
      select
        creation_month,
        count(*)
      from
        buckets
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

dashboard "aws_s3_bucket_dashboard" {

  title = "AWS S3 Bucket Dashboard"

  tags = merge(local.s3_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.aws_s3_bucket_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_versioning_disabled_count.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_s3_bucket_unencrypted_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_public_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_logging_disabled_count.sql
      width = 2
    }

    # Costs
    card {
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
      type = "info"
      icon = "currency-dollar"
      width = 2
    }
  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Versioning Status"
      sql   = query.aws_s3_bucket_versioning_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "green"
        }
        point "disabled" {
          color = "red"
        }
      }      
    }

    chart {
      title  = "Default Encryption Status"
      sql    = query.aws_s3_bucket_by_default_encryption_status.sql
      type   = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "green"
        }
        point "disabled" {
          color = "red"
        }
      }  
    }

    chart {
      title  = "Public/Private"
      sql    = query.aws_s3_bucket_public_status.sql
      type   = "donut"
      width = 4

      series "count" {
        point "private" {
          color = "green"
        }
        point "public" {
          color = "red"
        }
      }
    }

    chart {
      title = "Logging Status"
      sql   = query.aws_s3_bucket_logging_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "green"
        }
        point "disabled" {
          color = "red"
        }
      }
    }

    chart {
      title = "Versioning MFA Status"
      sql   = query.aws_s3_bucket_versioning_mfa_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "green"
        }
        point "disabled" {
          color = "red"
        }
      }
    }

    chart {
      title = "Cross-Region Replication"
      sql   = query.aws_s3_bucket_cross_region_replication_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "green"
        }
        point "disabled" {
          color = "red"
        }
      }
    }

  }

  container {
    title = "Cost"
    width = 6

    table  {
      width = 6
      title = "Forecast"
      sql   = query.aws_s3_monthly_forecast_table.sql
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      sql   = query.aws_s3_bucket_cost_per_month.sql
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Buckets by Account"
      sql   = query.aws_s3_bucket_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Buckets by Region"
      sql   = query.aws_s3_bucket_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Buckets by Age"
      sql   = query.aws_s3_bucket_by_creation_month.sql
      type  = "column"
      width = 4
    }

  }

}
