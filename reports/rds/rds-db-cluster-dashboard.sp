query "aws_rds_db_cluster_count" {
  sql = <<-EOQ
    select count(*) as "RDS DB Clusters" from aws_rds_db_cluster
  EOQ
}

query "aws_rds_unencrypted_db_cluster_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted Clusters' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_rds_db_cluster
    where
      not storage_encrypted
  EOQ
}

query "aws_rds_db_cluster_not_in_vpc_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Clusters not in VPC' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_rds_db_cluster
    where
      vpc_security_groups is null
  EOQ
}

query "aws_rds_db_cluster_cost_per_month" {
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


query "aws_rds_db_cluster_cost_last_30_counter" {
  sql = <<-EOQ
    select
       'Cost - Last 30 Days' as label,
       sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_daily
    where
      service = 'Amazon Relational Database Service'
      and period_start  >=  CURRENT_DATE - INTERVAL '30 day'
  EOQ
}


query "aws_rds_db_cluster_cost_by_usage_types_12mo" {
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

query "aws_rds_db_cluster_cost_30_60_counter" {
  sql = <<-EOQ
    select
      'Cost - Penultimate 30 Days' as label,
       sum(unblended_cost_amount)::numeric::money as value
    from
      aws_cost_by_service_daily
    where
      service = 'Amazon Relational Database Service'
      and period_start  between CURRENT_DATE - INTERVAL '60 day' and CURRENT_DATE - INTERVAL '30 day'

  EOQ

}

query "aws_rds_db_cluster_cost_by_usage_types_30day" {
  sql = <<-EOQ
    select
       usage_type,
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_daily
    where
      service = 'Amazon Relational Database Service'
      --and period_end >= date_trunc('month', CURRENT_DATE::timestamp)
      and period_end >=  CURRENT_DATE - INTERVAL '30 day'

    group by
      usage_type
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_rds_db_cluster_cost_by_account_30day" {
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


query "aws_rds_db_cluster_cost_by_account_12mo" {
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



query "aws_rds_db_cluster_by_account" {
  sql = <<-EOQ


    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_rds_db_cluster as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc

  EOQ
}


query "aws_rds_db_cluster_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_rds_db_cluster as i
    group by
      region
  EOQ
}


query "aws_rds_db_cluster_by_engine_type" {
  sql = <<-EOQ
    select engine as "Engine Type", count(*) as "Clusters" from aws_rds_db_cluster group by engine order by engine
  EOQ
}

query "aws_rds_db_cluster_logging_status" {
  sql = <<-EOQ
  with logging_stat as(
    select
      db_cluster_identifier
    from
      aws_rds_db_cluster
    where
      (engine like any (array ['mariadb', '%mysql']) and enabled_cloudwatch_logs_exports ?& array ['audit','error','general','slowquery'] )or
      ( engine like any (array['%postgres%']) and enabled_cloudwatch_logs_exports ?& array ['postgresql','upgrade'] ) or
      ( engine like 'oracle%' and enabled_cloudwatch_logs_exports ?& array ['alert','audit', 'trace','listener'] ) or
      ( engine = 'sqlserver-ex' and enabled_cloudwatch_logs_exports ?& array ['error'] ) or
      ( engine like 'sqlserver%' and enabled_cloudwatch_logs_exports ?& array ['error','agent'] )
     )
  select
    'Enabled' as "Logging Status",
    count(db_cluster_identifier) as "Total"
  from
    logging_stat
union
  select
    'Disabled' as "Logging Status",
    count( db_cluster_identifier) as "Total"
  from
    aws_rds_db_cluster as s where s.db_cluster_identifier not in (select db_cluster_identifier from logging_stat)
  EOQ
}

query "aws_rds_db_cluster_multiple_az_status" {
  sql = <<-EOQ
    with multiaz_stat as (
    select
      distinct db_cluster_identifier as name
    from
      aws_rds_db_cluster
    where
      multi_az
    group by name
 )
  select
    'Enabled' as "Multi-AZ Status",
    count(name) as "Total"
  from
    multiaz_stat
union
  select
    'Disabled' as "Multi-AZ Status",
    count( db_cluster_identifier) as "Total"
  from
    aws_rds_db_cluster as s where s.db_cluster_identifier not in (select name from multiaz_stat)
  EOQ
}

query "aws_rds_db_cluster_deletion_protection_status" {
  sql = <<-EOQ
    with deletion_protection as (
    select
      distinct db_cluster_identifier as name
    from
      aws_rds_db_cluster
    where
      deletion_protection
    group by name
 )
  select
    'Enabled' as "Deletition Protection Status",
    count(name) as "Total"
  from
    deletion_protection
union
  select
    'Disabled' as "Deletition Protection Status",
    count( db_cluster_identifier) as "Total"
  from
    aws_rds_db_cluster as s where s.db_cluster_identifier not in (select name from deletion_protection)
  EOQ
}


query "aws_rds_db_cluster_iam_authentication_enabled" {
  sql = <<-EOQ
    with iam_authentication_stat as (
    select
      distinct db_cluster_identifier as name
    from
      aws_rds_db_cluster
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
    aws_rds_db_cluster as s where s.db_cluster_identifier not in (select name from iam_authentication_stat)
  EOQ
}

query "aws_rds_db_cluster_by_state" {
  sql = <<-EOQ
    select
      status,
      count(status)
    from
      aws_rds_db_cluster
    group by
      status
  EOQ
}

query "aws_rds_db_cluster_with_no_snapshots" {
  sql = <<-EOQ
    select
      v.db_cluster_identifier,
      v.account_id,
      v.region
    from
      aws_rds_db_cluster as v
    left join aws_rds_db_cluster_snapshot as s on v.db_cluster_identifier = s.db_cluster_identifier
    group by
      v.account_id,
      v.region,
      v.db_cluster_identifier
    having
      count(s.db_cluster_snapshot_attributes) = 0
  EOQ
}

query "aws_rds_db_cluster_by_creation_month" {
  sql = <<-EOQ
    with clusters as (
      select
        title,
        create_time,
        to_char(create_time,
          'YYYY-MM') as creation_month
      from
        aws_rds_db_cluster
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
      months.month desc
  EOQ
}

dashboard "aws_rds_db_cluster_dashboard" {

  title = "AWS RDS DB Cluster Dashboard"

  container {

    card {
      sql   = query.aws_rds_db_cluster_count.sql
      width = 2
    }

    card {
      sql   = query.aws_rds_unencrypted_db_cluster_count.sql
      width = 2
    }

    card {
      sql   = query.aws_rds_db_cluster_not_in_vpc_count.sql
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

   card {
      sql   = query.aws_rds_db_cluster_cost_last_30_counter.sql
      width = 2
    }

  card {
      sql   = query.aws_rds_db_cluster_cost_30_60_counter.sql
      width = 2
    }

  }


    container {
      title = "Analysis"


      #title = "Counts"
      chart {
        title = "RDS DB Clusters by Account"
        sql   = query.aws_rds_db_cluster_by_account.sql
        type  = "column"
        width = 3
      }


      chart {
        title = "RDS DB Clusters by Region"
        sql   = query.aws_rds_db_cluster_by_region.sql
        type  = "column"
        width = 3
      }

      chart {
        title = "RDS DB Clusters by State"
        sql   = query.aws_rds_db_cluster_by_state.sql
        type  = "column"
        width = 3
      }

      chart {
        title = "RDS DB Clusters by Type"
        sql   = query.aws_rds_db_cluster_by_engine_type.sql
        type  = "column"
        width = 3
      }

    }

  container {
    title = "Costs"
    chart {
      title = "RDS Monthly Unblended Cost"
      type  = "line"
      sql   = query.aws_rds_db_cluster_cost_per_month.sql
      width = 4
    }

   chart {
      title = "RDS Cost by Usage Type - last 30 days"
      type  = "donut"
      sql   = query.aws_rds_db_cluster_cost_by_usage_types_30day.sql
      width = 2
    }

   chart {
      title = "RDS Cost by Usage Type - Last 12 months"
      type  = "donut"
      sql   = query.aws_rds_db_cluster_cost_by_usage_types_12mo.sql
      width = 2
    }


    chart {
      title = "RDS Cost by Account - MTD"

      type  = "donut"
      sql   = query.aws_rds_db_cluster_cost_by_account_30day.sql
       width = 2
    }

    chart {
      title = "RDS Cost By Account - Last 12 months"
      type  = "donut"
      sql   = query.aws_rds_db_cluster_cost_by_account_12mo.sql
      width = 2
    }
  }

  container {
    title = "Assessments"

    chart {
      title = "Logging Status"
      sql = query.aws_rds_db_cluster_logging_status.sql
      type  = "donut"
      width = 3

      series "Enabled" {
         color = "green"
      }
    }

    chart {
      title = "Multi-AZ Status"
      sql = query.aws_rds_db_cluster_multiple_az_status.sql
      type  = "donut"
      width = 3

    }

    chart {
      title = "Snapshot Status"
      sql = query.aws_rds_db_cluster_with_no_snapshots.sql
      type  = "donut"
      width = 3

    }

    chart {
      title = "Deletition Protection Status"
      sql = query.aws_rds_db_cluster_deletion_protection_status.sql
      type  = "donut"
      width = 3

    }
  }

#   container {
#     title  = "Performance & Utilization"

#     chart {
#       title = "Top 10 CPU - Last 7 days"
#       sql   = query.aws_rds_db_instance_top10_cpu_past_week.sql
#       type  = "line"
#       width = 6
#     }

#     chart {
#       title = "Average max daily CPU - Last 30 days"
#       sql   = query.aws_rds_db_instance_by_cpu_utilization_category.sql
#       type  = "column"
#       width = 6
#     }
#   }

  container {
    title   = "Resources by Age"

    chart {
      title = "RDS DB Cluster by Creation Month"
      sql   = query.aws_rds_db_cluster_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest RDS DB Clusters"
      width = 4

      sql = <<-EOQ
        select
          title as "cluster",
          (current_date - create_time)::text as "Age in Days",
          account_id as "Account"
        from
          aws_rds_db_cluster
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest RDS DB Clusters"
      width = 4

      sql = <<-EOQ
        select
          title as "cluster",
          current_date - create_time as "Age in Days",
          account_id as "Account"
        from
          aws_rds_db_cluster
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }
  }

}
