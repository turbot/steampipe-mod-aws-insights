query "aws_ebs_volume_count" {
  sql = <<-EOQ
    select count(*) as "Volumes" from aws_ebs_volume
  EOQ
}

query "aws_ebs_volume_storage_total" {
  sql = <<-EOQ
    select
      sum(size) as "Total Storage"
    from
      aws_ebs_volume
  EOQ
}

query "aws_ebs_encrypted_volume_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted Volumes' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ebs_volume
    where
      not encrypted
  EOQ
}

query "aws_ebs_unattached_volume_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unattached Volumes' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ebs_volume
    where
      attachments is null
  EOQ
}

query "aws_ebs_volume_cost_per_month" {
  sql = <<-EOQ
    select
       to_char(period_start, 'Mon-YY') as "Month",
       sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'EC2 - Other'
      and usage_type like '%EBS:%'
    group by
      period_start
    order by
      period_start
  EOQ
}

query "aws_ebs_volume_cost_by_usage_types_mtd" {
  sql = <<-EOQ
    select
       usage_type,
       sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly as c
    where
      service = 'EC2 - Other'
      and usage_type like '%EBS:%'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
    group by
      usage_type
    having
      round(sum(unblended_cost_amount)::numeric,2) > 0
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_ebs_volume_cost_by_usage_types_12mo" {
  sql = <<-EOQ
    select
       usage_type,
       sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly as c
    where
      service = 'EC2 - Other'
      and usage_type like '%EBS:%'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      usage_type
    having
      round(sum(unblended_cost_amount)::numeric,2) > 0
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_ebs_volume_cost_by_account_mtd" {
  sql = <<-EOQ
    select
       a.title as "account",
       sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'EC2 - Other'
      and usage_type like '%EBS:%'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
    group by
      account
    order by
      account
  EOQ
}

query "aws_ebs_volume_cost_by_account_12mo" {
  sql = <<-EOQ
    select
       a.title as "account",
       sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'EC2 - Other'
      and usage_type like '%EBS:%'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      account
    order by
      account
  EOQ
}

query "aws_ebs_volume_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(v.*) as "volumes"
    from
      aws_ebs_volume as v,
      aws_account as a
    where
      a.account_id = v.account_id
    group by
      account
    order by
      account
  EOQ
}

query "aws_ebs_volume_storage_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      sum(v.size) as "GB"
    from
      aws_ebs_volume as v,
      aws_account as a
    where
      a.account_id = v.account_id
    group by
      account
    order by
      account
  EOQ
}

query "aws_ebs_volume_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "volumes" from aws_ebs_volume group by region order by region
  EOQ
}

query "aws_ebs_volume_storage_by_region" {
  sql = <<-EOQ
    select region as "Region", sum(size) as "GB" from aws_ebs_volume group by region order by region
  EOQ
}

query "aws_ebs_volume_by_type" {
  sql = <<-EOQ
    select volume_type as "Type", count(*) as "volumes" from aws_ebs_volume group by volume_type order by volume_type
  EOQ
}

query "aws_ebs_volume_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select encrypted,
        case when encrypted then
          'Enabled'
        else
          'Disabled'
        end encryption_status
      from
        aws_ebs_volume) as t
    group by
      encryption_status
    order by
      encryption_status desc
  EOQ
}

query "aws_ebs_volume_by_state" {
  sql = <<-EOQ
    select
      state,
      count(state)
    from
      aws_ebs_volume
    group by
      state
  EOQ
}

query "aws_ebs_volume_with_no_snapshots" {
  sql = <<-EOQ
    select
      v.volume_id,
      v.account_id,
      v.region
    from
      aws_ebs_volume as v
    left join aws_ebs_snapshot as s on v.volume_id = s.volume_id
    group by
      v.account_id,
      v.region,
      v.volume_id
    having
      count(s.snapshot_id) = 0
  EOQ
}

query "aws_ebs_volume_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        create_time,
        to_char(create_time,
          'YYYY-MM') as creation_month
      from
        aws_ebs_volume
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(create_time)
                from volumes)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    volumes_by_month as (
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
      volumes_by_month.count
    from
      months
      left join volumes_by_month on months.month = volumes_by_month.creation_month
    order by
      months.month;
  EOQ
}

report "aws_ebs_volume_dashboard" {

  title = "AWS EBS Volume Dashboard"

  container {

    # Analysis

    card {
      sql = query.aws_ebs_volume_count.sql
      width = 2
    }

    card {
      sql = query.aws_ebs_volume_storage_total.sql
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
          service = 'EC2 - Other'
          and usage_type like '%EBS:%'
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
          aws_cost_by_service_usage_type_monthly as c
        where
          service = 'EC2 - Other'
          and usage_type like '%EBS:%'
          and date_trunc('month', period_start) =  date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
      EOQ
      width = 2
    }

    # Assessments
    card {
      sql = query.aws_ebs_encrypted_volume_count.sql
      width = 2
    }

    card {
      sql = query.aws_ebs_unattached_volume_count.sql
      width = 2
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "Volumes by Account"
      sql = query.aws_ebs_volume_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volumes by Region"
      sql = query.aws_ebs_volume_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volume Storage by Account (GB)"
      sql = query.aws_ebs_volume_storage_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volume Storage by Region (GB)"
      sql = query.aws_ebs_volume_storage_by_region.sql
      type  = "column"
      width = 3
    }
  }

  container {
    title = "Costs"
    chart {
      title = "EBS Monthly Unblended Cost"

      type  = "line"
      sql   = query.aws_ebs_volume_cost_per_month.sql
      width = 4
    }

   chart {
      title = "EBS Cost by Usage Type - MTD"
      type  = "donut"
      sql   = query.aws_ebs_volume_cost_by_usage_types_mtd.sql
      width = 2
    }

   chart {
      title = "EBS Cost by Usage Type - 12 months"
      type  = "donut"
      sql   = query.aws_ebs_volume_cost_by_usage_types_12mo.sql
      width = 2
    }

    chart {
      title = "EBS Cost By Account - MTD"

      type  = "donut"
      sql   = query.aws_ebs_volume_cost_by_account_mtd.sql
      width = 2
    }

    chart {
      title = "EBS Cost By Account - 12 months"

      type  = "donut"
      sql   = query.aws_ebs_volume_cost_by_account_12mo.sql
      width = 2
    }
  }

  # donut charts in a 2 x 2 layout
  container {
    title = "Assessments"

    chart {
      title = "Encryption Status"
      sql = query.aws_ebs_volume_by_encryption_status.sql
      type  = "donut"
      width = 3

      series "Enabled" {
         color = "green"
      }
    }

    chart {
      title = "Volume State"
      sql = query.aws_ebs_volume_by_state.sql
      type  = "donut"
      width = 3

    }

    chart {
      title = "Volume Type"
      sql = query.aws_ebs_volume_by_type.sql
      type  = "donut"
      width = 3
    }
  }

  container {
    title  = "Performance & Utilization"

    chart {
      title = "Top 10 Average Read OPS - Last 7 days"
        type  = "line"
      width = 4
      sql     =  <<-EOQ
        with top_n as (
          select
            volume_id,
            avg(average)
          from
            aws_ebs_volume_metric_read_ops_daily
          where
            timestamp  >= CURRENT_DATE - INTERVAL '7 day'
          group by
            volume_id
          order by
            avg desc
          limit 10
        )
        select
            timestamp,
            volume_id,
            average
          from
            aws_ebs_volume_metric_read_ops_hourly
          where
            timestamp  >= CURRENT_DATE - INTERVAL '7 day'
            and volume_id in (select volume_id from top_n)
      EOQ
    }

    chart {
      title = "Top 10 Average write OPS - Last 7 days"
      type  = "line"
      width = 4
      sql     =  <<-EOQ
        with top_n as (
          select
            volume_id,
            avg(average)
          from
            aws_ebs_volume_metric_write_ops_daily
          where
            timestamp  >= CURRENT_DATE - INTERVAL '7 day'
          group by
            volume_id
          order by
            avg desc
          limit 10
        )
        select
            timestamp,
            volume_id,
            average
          from
            aws_ebs_volume_metric_write_ops_hourly
          where
            timestamp  >= CURRENT_DATE - INTERVAL '7 day'
            and volume_id in (select volume_id from top_n)
      EOQ
    }
  }

  container {
    title = "Resources by Age"

    chart {
      title = "Volume by Creation Month"
      sql = query.aws_ebs_volume_by_creation_month.sql
      type  = "column"
      width = 4
      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest volumes"
      width = 4

      sql = <<-EOQ
        select
          title as "volume",
          current_date - create_time as "Age in Days",
          account_id as "Account"
        from
          aws_ebs_volume
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest volumes"
      width = 4

      sql = <<-EOQ
        select
          title as "volume",
          current_date - create_time as "Age in Days",
          account_id as "Account"
        from
          aws_ebs_volume
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }
  }

}
