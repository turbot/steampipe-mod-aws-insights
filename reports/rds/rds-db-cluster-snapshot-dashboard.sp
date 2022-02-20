query "aws_rds_db_cluster_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "RDS DB Cluster Snapshots" from aws_rds_db_cluster_snapshot
  EOQ
}

query "aws_rds_unencrypted_db_cluster_snapshot_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted Cluster Snapshots' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster_snapshot
    where
      not storage_encrypted
  EOQ
}

query "aws_rds_db_cluster_snapshot_not_in_vpc_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Cluster Snapshots not in VPC' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster_snapshot
    where
      vpc_id is null
  EOQ
}

query "aws_rds_db_cluster_snapshot_cost_per_month" {
  sql = <<-EOQ
    select
       to_char(period_start, 'Mon-YY') as "Month",
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Relational Database Service'
    group by
      period_start
    order by
      period_start
  EOQ
}

query "aws_rds_db_cluster_snapshot_cost_by_usage_types_12mo" {
  sql = <<-EOQ
    select
       usage_type,
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Relational Database Service'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      usage_type
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_rds_db_cluster_snapshot_cost_by_account_30day" {
  sql = <<-EOQ
    select
       a.title as "account",
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'Amazon Relational Database Service'
      and period_end >=  CURRENT_DATE - INTERVAL '30 day'
    group by
      account
    order by
      account
  EOQ
}


query "aws_rds_db_cluster_snapshot_cost_by_account_12mo" {
  sql = <<-EOQ
    select
       a.title as "account",
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'Amazon Relational Database Service'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      account
    order by
      account
  EOQ
}



query "aws_rds_db_cluster_snapshot_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_rds_db_cluster_snapshot as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc

  EOQ
}


query "aws_rds_db_cluster_snapshot_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_rds_db_cluster_snapshot as i
    group by
      region
  EOQ
}


query "aws_rds_db_cluster_snapshot_by_engine_type" {
  sql = <<-EOQ
    select engine as "Engine Type", count(*) as "Cluster Snapshots" from aws_rds_db_cluster_snapshot group by engine order by engine
  EOQ
}


query "aws_rds_db_cluster_snapshot_iam_authentication_enabled" {
  sql = <<-EOQ
    with iam_authentication_stat as (
    select
      distinct db_cluster_identifier as name
    from
      aws_rds_db_cluster_snapshot
    where
      iam_database_authentication_enabled
    group by name
  )
  select
    'Enabled' as "IAM Authentication Status",
    count(name) as "Total"
  from
    iam_authentication_stat
  union
  select
    'Disabled' as "IAM Authentication Status",
    count( db_cluster_identifier) as "Total"
  from
    aws_rds_db_cluster_snapshot as s where s.db_cluster_identifier not in (select name from iam_authentication_stat)
  EOQ
}

query "aws_rds_db_cluster_snapshot_by_state" {
  sql = <<-EOQ
    select
      status,
      count(status)
    from
      aws_rds_db_cluster_snapshot
    group by
      status
  EOQ
}

query "aws_rds_db_cluster_snapshot_by_creation_month" {
  sql = <<-EOQ
    with snapshots as (
      select
        title,
        create_time,
        to_char(create_time,
          'YYYY-MM') as creation_month
      from
        aws_rds_db_cluster_snapshot
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
                from snapshots)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    snapshots_by_month as (
      select
        creation_month,
        count(*)
      from
        snapshots
      group by
        creation_month
    )
    select
      months.month,
      snapshots_by_month.count
    from
      months
      left join snapshots_by_month on months.month = snapshots_by_month.creation_month
    order by
      months.month desc
  EOQ
}

dashboard "aws_rds_db_cluster_snapshot_dashboard" {

  title = "AWS RDS DB Cluster Snapshot Dashboard"

  container {

    card {
      sql   = query.aws_rds_db_cluster_snapshot_count.sql
      width = 2
    }

    card {
      sql   = query.aws_rds_unencrypted_db_cluster_snapshot_count.sql
      width = 2
    }

    card {
      sql   = query.aws_rds_db_cluster_snapshot_not_in_vpc_count.sql
      width = 2
    }

   card {
      sql = <<-EOQ
        select
          'Cost - MTD' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_usage_type_monthly as c
        where
          service = 'Amazon Relational Database Service'
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
          service = 'Amazon Relational Database Service'
          and date_trunc('month', period_start) =  date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
      EOQ
      width = 2
    }
  }


    container {
      title = "Analysis"


      #title = "Counts"
      chart {
        title = "RDS DB Cluster Snapshots by Account"
        sql   = query.aws_rds_db_cluster_snapshot_by_account.sql
        type  = "column"
        width = 3
      }


      chart {
        title = "RDS DB Cluster Snapshots by Region"
        sql   = query.aws_rds_db_cluster_snapshot_by_region.sql
        type  = "column"
        width = 3
      }

      chart {
        title = "RDS DB Cluster Snapshots by State"
        sql   = query.aws_rds_db_cluster_snapshot_by_state.sql
        type  = "column"
        width = 3
      }

      chart {
        title = "RDS DB Cluster Snapshots by Type"
        sql   = query.aws_rds_db_cluster_snapshot_by_engine_type.sql
        type  = "column"
        width = 3
      }

    }

  container {
    title = "Costs"
    chart {
      title = "RDS Monthly Unblended Cost"
      type  = "line"
      sql   = query.aws_rds_db_cluster_snapshot_cost_per_month.sql
      width = 4
    }

   chart {
      title = "RDS Cost by Usage Type - Last 12 months"
      type  = "donut"
      sql   = query.aws_rds_db_cluster_snapshot_cost_by_usage_types_12mo.sql
      width = 2
    }


    chart {
      title = "RDS Cost by Account - MTD"
      type  = "donut"
      sql   = query.aws_rds_db_cluster_snapshot_cost_by_account_30day.sql
       width = 2
    }

    chart {
      title = "RDS Cost By Account - Last 12 months"
      type  = "donut"
      sql   = query.aws_rds_db_cluster_snapshot_cost_by_account_12mo.sql
      width = 2
    }
  }

  container {
    title = "Assessments"

    # chart {
    #   title = "Logging Status"
    #   sql = query.aws_rds_db_cluster_snapshot_logging_status.sql
    #   type  = "donut"
    #   width = 3

    #   series "Enabled" {
    #      color = "green"
    #   }
    # }

  }


  container {
    title   = "Resources by Age"

    chart {
      title = "RDS DB Cluster Snapshots by Creation Month"
      sql   = query.aws_rds_db_cluster_snapshot_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest RDS DB Cluster Snapshots"
      width = 4

      sql = <<-EOQ
        select
          title as "Snapshot",
          (current_date - create_time)::text as "Age in Days",
          account_id as "Account"
        from
          aws_rds_db_cluster_snapshot
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest RDS DB Cluster Snapshots"
      width = 4

      sql = <<-EOQ
        select
          title as "Snapshot",
          (current_date - create_time)::text as "Age in Days",
          account_id as "Account"
        from
          aws_rds_db_cluster_snapshot
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }
  }

}
