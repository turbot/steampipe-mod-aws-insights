query "aws_kms_key_count" {
  sql = <<-EOQ
    select count(*) as "Keys" from aws_kms_key
  EOQ
}

query "aws_kms_key_customer_managed_count" {
  sql = <<-EOQ
    select
      count(*)as "Customer Managed Keys"
    from
      aws_kms_key
    where
      key_manager = 'CUSTOMER'
  EOQ
}

query "aws_inactive_kms_key_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Inactive Keys' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_kms_key
    where
      not enabled
  EOQ
}

query "aws_kms_key_rotation_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Rotation Disabled Keys' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_kms_key
    where
      not key_rotation_enabled
  EOQ
}

query "aws_kms_key_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount)::numeric as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'AWS Key Management Service'
    group by
      period_start
    order by
      period_start
  EOQ
}

#query "aws_kms_key_cost_by_account_12mo" {
#  sql = <<-EOQ
#    select
#      a.title as "account",
#      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
#   from
#      aws_cost_by_service_monthly as c,
#      aws_account as a
#    where
#      a.account_id = c.account_id
#      and service = 'AWS Key Management Service'
#      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
#    group by
#      account
#    order by
#     account
# EOQ
#}

query "aws_kms_key_by_origin" {
  sql = <<-EOQ
    select
      origin,
      count(origin)
    from
      aws_kms_key
    group by
      origin
  EOQ
}

query "aws_kms_key_by_account" {

  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_kms_key as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc
  EOQ
}

query "aws_kms_key_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_kms_key as i
    group by
      region
  EOQ
}

query "aws_kms_key_by_state" {
  sql = <<-EOQ
    select
      key_state,
      count(key_state)
    from
      aws_kms_key
    group by
      key_state
  EOQ
}

query "aws_kms_key_usage_status" {
  sql = <<-EOQ
    select
      key_usage,
      count(key_usage)
    from
      aws_kms_key
    group by
      key_usage
  EOQ
}

query "aws_kms_key_rotation_status" {
  sql = <<-EOQ
    select
      rotation_status,
      count(*)
    from (
      select
        case when key_rotation_enabled then
          'Enabled'
        else
          'Disabled'
        end rotation_status
      from
        aws_kms_key) as t
    group by
      rotation_status
    order by
      rotation_status desc
  EOQ
}

query "aws_kms_key_by_creation_month" {
    sql = <<-EOQ
    with keys as (
      select
        title,
        creation_date,
        to_char(creation_date,
          'YYYY-MM') as creation_month
      from
        aws_kms_key
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
                from keys)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    keys_by_month as (
      select
        creation_month,
        count(*)
      from
        keys
      group by
        creation_month
    )
    select
      months.month,
      keys_by_month.count
    from
      months
      left join keys_by_month on months.month = keys_by_month.creation_month
    order by
      months.month desc;
  EOQ
}

#query "aws_kms_key_cost_top_usage_types_mtd" {
#  sql = <<-EOQ
#    select
#      usage_type,
#      sum(unblended_cost_amount)::numeric as "Unblended Cost"
#      --sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
#    from
#      aws_cost_by_service_usage_type_monthly
#    where
#      service = 'AWS Key Management Service'
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

#query "aws_kms_key_cost_by_usage_types_12mo" {
#  sql = <<-EOQ
#    select
#       usage_type,
#       sum(unblended_cost_amount)::numeric as "Unblended Cost"
#       --sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
#
#    from
#      aws_cost_by_service_usage_type_monthly
#    where
#      service = 'AWS Key Management Service'
#      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
#   group by
#      usage_type
#    having
#      round(sum(unblended_cost_amount)::numeric,2) > 0
#    order by
#      sum(unblended_cost_amount) desc
#  EOQ
#}

#query "aws_kms_key_cost_by_account_mtd" {
#  sql = <<-EOQ
#    select
#       a.title as "account",
#       sum(unblended_cost_amount)::numeric as "Unblended Cost"
#       --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
#    from
#      aws_cost_by_service_monthly as c,
#      aws_account as a
#    where
#      a.account_id = c.account_id
#      and service = 'AWS Key Management Service'
#      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
#    group by
#      account
#    order by
#      account
#  EOQ
#}

dashboard "aws_kms_key_dashboard" {

  title = "AWS KMS Key Dashboard"

  container {

    # Analysis
    card {
      sql   = query.aws_kms_key_count.sql
      width = 2
    }

    card {
      sql   = query.aws_kms_key_customer_managed_count.sql
      width = 2
      type = "info"
    }

    # Costs
    card {
      type  = "info"
      icon = "currency-dollar"

      sql = <<-EOQ
        select
          'Cost - MTD' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_monthly
        where
          service = 'AWS Key Management Service'
          and period_end > date_trunc('month', CURRENT_DATE::timestamp)
      EOQ
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
          service = 'AWS Key Management Service'
          and date_trunc('month', period_start) =  date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
      EOQ
      type = "info"
      icon = "currency-dollar"
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_inactive_kms_key_count.sql
      width = 2
    }

    card {
      sql   = query.aws_kms_key_rotation_enabled_count.sql
      width = 2
    }

  }

  container {
    title = "Analysis"


    #title = "Counts"
    chart {
      title = "Keys by Account"
      sql   = query.aws_kms_key_by_account.sql
      type  = "column"
      width = 3
    }


    chart {
      title = "Keys by Region"
      sql   = query.aws_kms_key_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by State"
      sql   = query.aws_kms_key_by_state.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Origin"
      sql   = query.aws_kms_key_by_origin.sql
      type  = "column"
      width = 3
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Usage Status"
      sql = query.aws_kms_key_usage_status.sql
      type  = "donut"
      width = 3
    }

    chart {
      title = "Rotation Status"
      sql = query.aws_kms_key_rotation_status.sql
      type  = "donut"
      width = 3
    }

  }

  container {
    title = "Costs"
     width = 3

    chart {
      title = "KMS Monthly Unblended Cost"
      type  = "line"
      sql   = query.aws_kms_key_cost_per_month.sql
      // width = 4
    }
  }

  container {
    title = "Resource Age"
    width = 9

    chart {
      title = "Key by Creation Month"
      sql   = query.aws_kms_key_by_creation_month.sql
      type  = "column"
      width = 6
      series "month" {
        color = "green"
      }
    }

    table {
      title = "KMS Keys To Be Deleted Within 7 days"
      width = 6

      sql = <<-EOQ
        select
          title as "Key",
          (deletion_date - current_date) as "Deleting After",
          aliases as "Aliases",
          account_id as "Account"
        from
          aws_kms_key
        where
          extract(day from deletion_date - current_date) <= 7
        order by
          "Deleting After" desc,
          title
        limit 5
      EOQ
    }
  }

#  chart {
#      title = "KMS Cost by Usage Type - MTD"
#       type  = "donut"
#      sql   = query.aws_kms_key_cost_top_usage_types_mtd.sql
#      width = 2
#       legend {
#        position  = "bottom"
#      }
#    }

#   chart {
#      title = "KMS Cost by Usage Type - Last 12 months"
#      type  = "donut"
#      sql   = query.aws_kms_key_cost_by_usage_types_12mo.sql
#      width = 2

#      legend {
#        position  = "right"
#      }
#    }

#    chart {
#      title = "KMS Cost by Account - MTD"
#     type  = "donut"
#      sql   = query.aws_kms_key_cost_by_account_mtd.sql
#       width = 2
#    }

#    chart {
#      title = "KMS Cost by Account - 12 months"
#      type  = "donut"
#      sql   = query.aws_kms_key_cost_by_account_12mo.sql
#     width = 2
#    }

}
