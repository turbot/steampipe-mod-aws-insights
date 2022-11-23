dashboard "aws_rds_db_cluster_age_report" {

  title         = "AWS RDS DB Cluster Age Report"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_report_age.md")

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.aws_rds_db_cluster_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_rds_db_cluster_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_rds_db_cluster_30_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.aws_ebs_volume_30_90_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_rds_db_clustere_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.aws_rds_db_cluster_1_year_count
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    query = query.aws_rds_db_cluster_age_table
  }

}

query "aws_rds_db_cluster_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_rds_db_cluster
    where
      create_time > now() - '1 days' :: interval;
  EOQ
}

query "aws_rds_db_cluster_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_rds_db_cluster
    where
      create_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "aws_rds_db_cluster_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_rds_db_cluster
    where
      create_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "aws_rds_db_clustere_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_rds_db_cluster
    where
      create_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "aws_rds_db_cluster_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_rds_db_cluster
    where
      create_time <= now() - '1 year' :: interval;
  EOQ
}

query "aws_rds_db_cluster_age_table" {
  sql = <<-EOQ
    select
      c.db_cluster_identifier as "DB Cluster Identifier",
      now()::date - c.create_time::date as "Age in Days",
      c.create_time as "Create Time",
      c.status as "Status",
      a.title as "Account",
      c.account_id as "Account ID",
      c.arn as "ARN"
    from
      aws_rds_db_cluster as c,
      aws_account as a
    where
      c.account_id = a.account_id
    order by
      c.db_cluster_identifier;
  EOQ
}
