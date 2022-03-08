dashboard "aws_redshift_cluster_age_report" {

  title = "AWS Redshift Cluster Age Report"

  tags = merge(local.redshift_common_tags, {
    type     = "Report"
    category = "Age"
  })

   container {

    card {
      sql   = query.aws_redshift_cluster_count.sql
      width = 2
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_redshift_cluster_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_redshift_cluster_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_redshift_cluster_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_redshift_cluster_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_redshift_cluster_1_year_count.sql
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Cluster Identifier" {
      href = "/aws_insights.dashboard.aws_redshift_cluster_detail?input.cluster_arn={{.ARN|@uri}}"
    }

    sql = query.aws_redshift_cluster_age_table.sql
  }

}

query "aws_redshift_cluster_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_redshift_cluster
    where
      cluster_create_time > now() - '1 days' :: interval;
  EOQ
}

query "aws_redshift_cluster_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_redshift_cluster
    where
      cluster_create_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "aws_redshift_cluster_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_redshift_cluster
    where
      cluster_create_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "aws_redshift_cluster_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_redshift_cluster
    where
      cluster_create_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "aws_redshift_cluster_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_redshift_cluster
    where
      cluster_create_time <= now() - '1 year' :: interval;
  EOQ
}

query "aws_redshift_cluster_age_table" {
  sql = <<-EOQ
    select
      c.cluster_identifier as "Cluster Identifier",
      now()::date - c.cluster_create_time::date as "Age in Days",
      c.cluster_create_time as "Create Time",
      c.cluster_status as "Status",
      a.title as "Account",
      c.account_id as "Account ID",
      c.region as "Region",
      c.arn as "ARN"
    from
      aws_redshift_cluster as c,
      aws_account as a
    where
      c.account_id = a.account_id
    order by
      c.cluster_identifier
  EOQ
}