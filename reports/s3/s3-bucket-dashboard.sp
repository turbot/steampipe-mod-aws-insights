query "aws_s3_bucket_count" {
  sql = <<-EOQ
    select count(*) as "Buckets" from aws_s3_bucket
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
      period_start
  EOQ
}

#query "aws_s3_bucket_cost_by_usage_types_12mo" {
#  sql = <<-EOQ
#    select
#      usage_type,
#      sum(unblended_cost_amount)::numeric as "Unblended Cost"
#    from
#      aws_cost_by_service_usage_type_monthly
#    where
#     service = 'Amazon Simple Storage Service'
#      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
#   group by
#      usage_type
#    having
#      round(sum(unblended_cost_amount)::numeric,2) > 0
#    order by
#      sum(unblended_cost_amount) desc
#  EOQ
#}

# query "aws_s3_bucket_cost_top_usage_types_mtd" {
#  sql = <<-EOQ
#    select
#      usage_type,
#      sum(unblended_cost_amount)::numeric as "Unblended Cost"
#    from
#      aws_cost_by_service_usage_type_monthly
#    where
#      service = 'Amazon Simple Storage Service'
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

#query "aws_s3_bucket_cost_by_account_mtd" {
# sql = <<-EOQ
#    select
#      a.title as "account",
#      sum(unblended_cost_amount)::numeric as "Unblended Cost"
#    from
#      aws_cost_by_service_monthly as c,
#      aws_account as a
#    where
#      a.account_id = c.account_id
#      and service = 'Amazon Simple Storage Service'
#      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
#    group by
#      account
#    order by
#      account
#  EOQ
#}

#query "aws_s3_bucket_cost_by_account_12mo" {
# sql = <<-EOQ
#    select
#      a.title as "account",
#     sum(unblended_cost_amount)::numeric as "Unblended Cost"
#   from
#      aws_cost_by_service_monthly as c,
#     aws_account as a
#   where
#      a.account_id = c.account_id
#      and service = 'Amazon Simple Storage Service'
#      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
#    group by
#      account
#    order by
#      account
#  EOQ
#}

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
    order by count(i.*) desc
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
      region
  EOQ
}

query "aws_s3_bucket_by_default_encryption_status" {
  sql = <<-EOQ
    with default_encryption as(
      select
        case when server_side_encryption_configuration is not null then 'Enabled' else 'Disabled'
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
      visibility
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
      months.month desc;
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
                when b.name = r.name and r.rep_status = 'Enabled' then 'Enabled' else 'Disabled'
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
            visibility
      EOQ
}

query "aws_s3_bucket_logging_status" {
  sql = <<-EOQ
    with logging_status as(
      select
        case when logging -> 'TargetBucket' is not null then 'Enabled' else 'Disabled'
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
      visibility
      EOQ
}

query "aws_s3_bucket_versioning_status" {
  sql = <<-EOQ
    with versioning_status as(
      select
        case
          when versioning_enabled then 'Enabled' else 'Disabled'
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
      visibility
  EOQ
}

dashboard "aws_s3_bucket_dashboard" {

  title = "AWS S3 Bucket Dashboard"

  container {

    # Analysis
    card {
      sql   = query.aws_s3_bucket_count.sql
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

    card {
      sql = <<-EOQ
        select
          'Cost - Previous Month' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_monthly
        where
          service = 'Amazon Simple Storage Service'
          and date_trunc('month', period_start) =  date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
      EOQ
      type = "info"
      icon = "currency-dollar"
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
      sql = query.aws_s3_bucket_logging_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_public_policy_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_block_public_acls_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_block_public_policy_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_ignore_public_acls_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_restrict_public_buckets_disabled_count.sql
      width = 2
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Buckets by Account"
      sql   = query.aws_s3_bucket_by_account.sql
      type  = "column"
      width = 3
    }


    chart {
      title = "Buckets by Region"
      sql   = query.aws_s3_bucket_by_region.sql
      type  = "column"
      width = 3
    }
  }

    container {
    title = "Assesments"
    width = 12

    chart {
      title  = "Default Encryption Status"
      sql    = query.aws_s3_bucket_by_default_encryption_status.sql
      type   = "donut"
      width = 3
    }

   chart {
      title = "Cross-Region Replication Status"
      sql   = query.aws_s3_bucket_cross_region_replication_status.sql
      type  = "donut"
      width = 3
    }

   chart {
      title = "Logging Status"
      sql   = query.aws_s3_bucket_logging_status.sql
      type  = "donut"
      width = 3
    }

    chart {
      title = "Versioning Status"
      sql   = query.aws_s3_bucket_versioning_status.sql
      type  = "donut"
      width = 3
    }
  }

  container {
    title = "Costs"
    width = 3

    chart {
      title = "S3 Monthly Unblended Cost"
      type  = "line"
      sql   = query.aws_s3_bucket_cost_per_month.sql
      //width = 4
    }
  }

  container {
    title = "Resource Age"
    width = 3

    chart {
      title = "Bucket by Creation Month"
      sql   = query.aws_s3_bucket_by_creation_month.sql
      type  = "column"
      //width = 4
      series "month" {
        color = "green"
      }
    }
  }

#  chart {
#       title = "S3 Cost by Usage Type - MTD"
#       type  = "donut"
#      sql   = query.aws_s3_bucket_cost_top_usage_types_mtd.sql
#       width = 2

#       legend {
#        position  = "bottom"
#      }
#    }

#    chart {
#       title = "S3 Cost by Usage Type - 12 months"
#       type  = "donut"
#       sql   = query.aws_s3_bucket_cost_by_usage_types_12mo.sql
#       width = 2

#       legend {
#        position  = "right"
#      }
#     }

#     chart {
#       title = "S3 Cost by Account - MTD"
#       type  = "donut"
#       sql   = query.aws_s3_bucket_cost_by_account_mtd.sql
#       width = 2
#     }

#     chart {
#       title = "S3 Cost by Account - 12 months"
#       type  = "donut"
#       sql   = query.aws_s3_bucket_cost_by_account_12mo.sql
#       width = 2
#     }

}
