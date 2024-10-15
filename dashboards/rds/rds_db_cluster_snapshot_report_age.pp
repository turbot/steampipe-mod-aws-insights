dashboard "rds_db_cluster_snapshot_age_report" {

  title         = "AWS RDS DB Cluster Snapshot Age Report"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_snapshot_report_age.md")

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.rds_db_cluster_snapshot_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.rds_db_cluster_snapshot_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.rds_db_cluster_snapshot_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.rds_db_cluster_snapshot_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.rds_db_cluster_snapshot_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.rds_db_cluster_snapshot_1_year_count
    }

  }

  container {

    table {
      column "Account ID" {
        display = "none"
      }

      column "ARN" {
        display = "none"
      }

      column "DB Cluster Snapshot Identifier" {
        href = "${dashboard.rds_db_cluster_snapshot_detail.url_path}?input.db_cluster_snapshot_arn={{.ARN | @uri}}"
      }

      query = query.rds_db_cluster_snapshot_age_table
    }

  }

}

query "rds_db_cluster_snapshot_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_rds_db_cluster_snapshot
    where
      create_time > now() - '1 days' :: interval;
  EOQ
}

query "rds_db_cluster_snapshot_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_rds_db_cluster_snapshot
    where
      create_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "rds_db_cluster_snapshot_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_rds_db_cluster_snapshot
    where
      create_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "rds_db_cluster_snapshot_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_rds_db_cluster_snapshot
    where
      create_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "rds_db_cluster_snapshot_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_rds_db_cluster_snapshot
    where
      create_time <= now() - '1 year' :: interval;
  EOQ
}

query "rds_db_cluster_snapshot_age_table" {
  sql = <<-EOQ
    select
      s.db_cluster_snapshot_identifier as "DB Cluster Snapshot Identifier",
      now()::date - s.create_time::date as "Age in Days",
      s.create_time as "Create Time",
      s.status as "Status",
      a.title as "Account",
      s.account_id as "Account ID",
      s.region as "Region",
      s.arn as "ARN"
    from
      aws_rds_db_cluster_snapshot as s,
      aws_account as a
    where
      s.account_id = a.account_id
    order by
      s.create_time,
      s.db_cluster_snapshot_identifier;
  EOQ
}
