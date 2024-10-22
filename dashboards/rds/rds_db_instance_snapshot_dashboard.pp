dashboard "rds_db_instance_snapshot_dashboard" {

  title         = "AWS RDS DB Instance Snapshot Dashboard"
  documentation = file("./dashboards/rds/docs/rds_db_instance_snapshot_dashboard.md")

  tags = merge(local.rds_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.rds_db_instance_snapshot_count
      width = 3
    }

    # Assessments
    card {
      query = query.rds_db_instance_snapshot_unencrypted_count
      width = 3
      href  = dashboard.rds_db_instace_snapshot_encryption_report.url_path
    }

  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      query = query.rds_db_instance_snapshot_by_encryption_status
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
      title = "IAM Authentication Status"
      query = query.rds_db_instance_snapshot_iam_authentication_enabled
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

    title = "Analysis"

    chart {
      title = "Snapshots by Account"
      query = query.rds_db_instance_snapshot_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by Region"
      query = query.rds_db_instance_snapshot_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by State"
      query = query.rds_db_instance_snapshot_by_state
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by Age"
      query = query.rds_db_instance_snapshot_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Snapshots by Engine Type"
      query = query.rds_db_instance_snapshot_by_engine_type
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "rds_db_instance_snapshot_count" {
  sql = <<-EOQ
    select count(*) as "RDS DB Instance Snapshots" from aws_rds_db_snapshot;
  EOQ
}

query "rds_db_instance_snapshot_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_snapshot
    where
      not encrypted;
  EOQ
}

# Assessment Queries

query "rds_db_instance_snapshot_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select encrypted,
        case when encrypted then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_rds_db_snapshot) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "rds_db_instance_snapshot_iam_authentication_enabled" {
  sql = <<-EOQ
    with iam_authentication_enabled as (
      select
        distinct db_instance_identifier as name
      from
        aws_rds_db_snapshot
      where
        iam_database_authentication_enabled
      group by name
    ),
    iam_authentication_status as (
      select
        case
          when e.name is not null then 'enabled'
          else 'disabled' end as iam_database_authentication
      from
        aws_rds_db_snapshot as c
        left join iam_authentication_enabled as e on c.db_instance_identifier = e.name
    )
    select
      iam_database_authentication,
      count(*)
    from
      iam_authentication_status
    group by
      iam_database_authentication;
  EOQ
}

# Analysis Queries

query "rds_db_instance_snapshot_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(i.*) as "total"
    from
      aws_rds_db_snapshot as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      a.title
    order by
      count(i.*) desc;
  EOQ
}

query "rds_db_instance_snapshot_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      aws_rds_db_snapshot as i
    group by
      region;
  EOQ
}

query "rds_db_instance_snapshot_by_state" {
  sql = <<-EOQ
    select
      status,
      count(status)
    from
      aws_rds_db_snapshot
    group by
      status;
  EOQ
}

query "rds_db_instance_snapshot_by_creation_month" {
  sql = <<-EOQ
    with snapshots as (
      select
        title,
        create_time,
        to_char(create_time,
          'YYYY-MM') as creation_month
      from
        aws_rds_db_snapshot
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
      months.month;
  EOQ
}

query "rds_db_instance_snapshot_by_engine_type" {
  sql = <<-EOQ
    select engine as "Engine Type", count(*) as "Instance Snapshots" from aws_rds_db_snapshot group by engine order by engine;
  EOQ
}
