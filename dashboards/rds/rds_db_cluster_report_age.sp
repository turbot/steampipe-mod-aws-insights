dashboard "aws_rds_db_cluster_age_report" {

  title = "AWS RDS DB Cluster Age Report"

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Age"
  })

   container {

    # Analysis
    card {
      sql   = query.aws_rds_db_cluster_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          aws_rds_db_cluster
        where
          create_time > now() - '1 days' :: interval;
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '1-30 Days' as label
        from
          aws_rds_db_cluster
        where
          create_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '30-90 Days' as label
        from
          aws_rds_db_cluster
        where
          create_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '90-365 Days' as label
        from
          aws_rds_db_cluster
        where
          create_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '> 1 Year' as label
        from
          aws_rds_db_cluster
        where
          create_time <= now() - '1 year' :: interval;
      EOQ
      width = 2
      type = "info"
    }

  }

  container {

    table {

      column "Account ID" {
        display = "none"
      }

      sql = <<-EOQ
        select
          v.title as "Cluster",
          -- date_trunc('day',age(now(),v.create_time))::text as "Age",
          now()::date - v.create_time::date as "Age in Days",
          v.create_time as "Create Time",
          a.title as "Account",
          v.account_id as "Account ID",
          v.status as "Status",
          v.arn as "ARN"
        from
          aws_rds_db_cluster as v,
          aws_account as a
        where
          v.account_id = a.account_id
        order by
          v.create_time,
          v.title;
      EOQ

    }

  }

}
