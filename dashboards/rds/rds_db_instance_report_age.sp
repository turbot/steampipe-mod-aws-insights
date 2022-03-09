dashboard "aws_rds_db_instance_age_report" {

  title         = "AWS RDS DB Instance Age Report"
  documentation = file("./dashboards/rds/docs/rds_db_instance_report_age.md")

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Age"
  })

   container {

    card {
      sql   = query.aws_rds_db_instance_count.sql
      width = 2
    }

     card {
      type  = "info"
      width = 2
      sql   = query.aws_rds_db_instance_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_rds_db_instance_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_rds_db_instance_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_rds_db_instance_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_rds_db_instance_1_year_count.sql
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "DB Instance Identifier" {
      href = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arnn={{.ARN | @uri}}"
    }

    sql = query.aws_rds_db_instance_age_table.sql
  }

}

query "aws_rds_db_instance_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_rds_db_instance
    where
      create_time > now() - '1 days' :: interval;
  EOQ
}

query "aws_rds_db_instance_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_rds_db_instance
    where
      create_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "aws_rds_db_instance_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_rds_db_instance
    where
      create_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "aws_rds_db_instance_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_rds_db_instance
    where
      create_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
  EOQ
}

query "aws_rds_db_instance_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_rds_db_instance
    where
      create_time <= now() - '1 year' :: interval;
  EOQ
}

query "aws_rds_db_instance_age_table" {
  sql = <<-EOQ
    select
      i.db_instance_identifier as "DB Instance Identifier",
      now()::date - i.create_time::date as "Age in Days",
      i.create_time as "Create Time",
      i.status as "Status",
      a.title as "Account",
      i.account_id as "Account ID",
      i.region as "Region",
      i.arn as "ARN"
    from
      aws_rds_db_instance as i,
      aws_account as a
    where
      i.account_id = a.account_id
    order by
      i.db_instance_identifier;
  EOQ
}
