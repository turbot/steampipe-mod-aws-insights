dashboard "aws_rds_db_instance_snapshot_age_report" {

  title = "AWS RDS DB Instance Snapshot Age Report"

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.aws_rds_db_instance_snapshot_count.sql
      width = 2
    }

   card {
      type  = "info"
      width = 2
      sql   = query.aws_rds_db_instance_snapshot_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_rds_db_instance_snapshot_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_rds_db_instance_snapshot_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_rds_db_instance_snapshot_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_rds_db_instance_snapshot_1_year_count.sql
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "DB Snapshot Identifier" {
      href = "/aws_insights.dashboard.aws_rds_db_snapshot_detail?input.db_snapshot_arn={{.ARN | @uri}}"
    }

    sql = query.aws_rds_db_instance_snapshot_age_table.sql
  }

}

query "aws_rds_db_instance_snapshot_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_rds_db_snapshot
    where
      create_time > now() - '1 days' :: interval;
  EOQ
}

query "aws_rds_db_instance_snapshot_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_rds_db_snapshot
    where
      create_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "aws_rds_db_instance_snapshot_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_rds_db_snapshot
    where
      create_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "aws_rds_db_instance_snapshot_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_rds_db_snapshot
    where
      create_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "aws_rds_db_instance_snapshot_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_rds_db_snapshot
    where
      create_time <= now() - '1 year' :: interval;
  EOQ
}

query "aws_rds_db_instance_snapshot_age_table" {
  sql = <<-EOQ
    select
      s.db_snapshot_identifier as "DB Snapshot Identifier",
      now()::date - s.create_time::date as "Age in Days",
      s.create_time as "Create Time",
      s.status as "Status",
      a.title as "Account",
      s.account_id as "Account ID",
      s.region as "Region",
      s.arn as "ARN"
    from
      aws_rds_db_snapshot as s,
      aws_account as a
    where
      s.account_id = a.account_id
    order by
      s.db_snapshot_identifier;
  EOQ
}
