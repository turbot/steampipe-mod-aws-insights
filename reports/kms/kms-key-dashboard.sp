query "aws_kms_key_count" {
  sql = <<-EOQ
    select count(*) as "KMS Keys" from aws_kms_key
  EOQ
}

query "aws_kms_key_aws_managed_count" {
  sql = <<-EOQ
    select
      count(*)as "AWS Managed Keys"
    from
      aws_kms_key
    where
      key_manager = 'AWS'
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
      'Inactive KMS Keys' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
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
      case count(*) when 0 then 'ok' else 'alert' end as style
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
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
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

query "aws_kms_key_cost_last_30_card" {
  sql = <<-EOQ
    select
      'Cost - Last 30 Days' as label,
       sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_daily
    where
      service = 'AWS Key Management Service'
      and period_start  >=  CURRENT_DATE - INTERVAL '30 day'
  EOQ
}

query "aws_kms_key_cost_by_usage_types_12mo" {
  sql = <<-EOQ
    select
      usage_type,
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'AWS Key Management Service'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      usage_type
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_kms_key_cost_30_60_card" {
  sql = <<-EOQ
    select
      'Cost - Penultimate 30 Days' as label,
      sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_daily
    where
      service = 'AWS Key Management Service'
      and period_start  between CURRENT_DATE - INTERVAL '60 day' and CURRENT_DATE - INTERVAL '30 day'
  EOQ
}

query "aws_kms_key_cost_by_usage_types_30day" {
  sql = <<-EOQ
    select
      usage_type,
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_daily
    where
      service = 'AWS Key Management Service'
      --and period_end >= date_trunc('month', CURRENT_DATE::timestamp)
      and period_end >=  CURRENT_DATE - INTERVAL '30 day'
    group by
      usage_type
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_kms_key_cost_by_account_30day" {
  sql = <<-EOQ
    select
      a.title as "account",
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'AWS Key Management Service'
      and period_end >=  CURRENT_DATE - INTERVAL '30 day'
    group by
      account
    order by
      account
  EOQ
}

query "aws_kms_key_cost_by_account_12mo" {
  sql = <<-EOQ
    select
      a.title as "account",
      sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'AWS Key Management Service'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      account
    order by
      account
  EOQ
}

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

query "aws_kms_key_pending_deletion" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Pending Deletion' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_kms_key
    where
      key_state = 'PendingDeletion'
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

report "aws_kms_key_summary" {

  title = "AWS KMS Key Dashboard"

  container {

    card {
      sql   = query.aws_kms_key_count.sql
      width = 2
    }

    card {
      sql   = query.aws_kms_key_aws_managed_count.sql
      width = 2
    }

    card {
      sql   = query.aws_kms_key_customer_managed_count.sql
      width = 2
    }

    card {
      sql   = query.aws_inactive_kms_key_count.sql
      width = 2
    }

    card {
      sql   = query.aws_kms_key_pending_deletion.sql
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
      title = "KMS Keys by Account"
      sql   = query.aws_kms_key_by_account.sql
      type  = "column"
      width = 3
    }


    chart {
      title = "KMS Keys by Region"
      sql   = query.aws_kms_key_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "KMS Keys by State"
      sql   = query.aws_kms_key_by_state.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "KMS Keys by Origin"
      sql   = query.aws_kms_key_by_origin.sql
      type  = "column"
      width = 3
    }

  }

  container {
    title = "Costs"

    chart {
      title = "KMS Monthly Cost"
      type  = "line"
      sql   = query.aws_kms_key_cost_per_month.sql
      width = 4
    }


   chart {
      title = "KMS Cost by Usage Type - last 30 days"
      type  = "donut"
      sql   = query.aws_kms_key_cost_by_usage_types_30day.sql
      width = 2
    }

   chart {
      title = "KMS Cost by Usage Type - Last 12 months"
      type  = "donut"
      sql   = query.aws_kms_key_cost_by_usage_types_12mo.sql
      width = 2
    }


    chart {
      title = "By Account - MTD"
      type  = "donut"
      sql   = query.aws_kms_key_cost_by_account_30day.sql
       width = 2
    }

    chart {
      title = "By Account - Last 12 months"
      type  = "donut"
      sql   = query.aws_kms_key_cost_by_account_12mo.sql
      width = 2
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Key Usage"
      sql = query.aws_kms_key_usage_status.sql
      type  = "donut"
      width = 3
    }

    table {
      title = "IAM Policy with decryption actions allowed on all keys"
      width = 4

      sql = <<-EOQ
        select
          distinct arn
        from
          aws_iam_policy,
          jsonb_array_elements(policy_std -> 'Statement') as statement
        where
          not is_aws_managed
          and statement ->> 'Effect' = 'Allow'
          and statement -> 'Resource' ?| array['*', 'arn:aws:kms:*:' || account_id || ':key/*', 'arn:aws:kms:*:' || account_id || ':alias/*']
          and statement -> 'Action' ?| array['*', 'kms:*', 'kms:decrypt', 'kms:reencryptfrom', 'kms:reencrypt*']
          limit 5;
      EOQ
    }

  }

  container {
    title   = "Resources by Age"

    chart {
      title = "KMS Keys by Creation Month"
      sql   = query.aws_kms_key_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }
    }

    table {
      title = "KMS Keys Deleting within 7 days"
      width = 4

      sql = <<-EOQ
        select
          title as "key",
          (deletion_date - current_date) as "Age in Days",
          account_id as "Account"
        from
          aws_kms_key
        where
          extract(day from deletion_date - current_date) <= 7
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }
  }

}


