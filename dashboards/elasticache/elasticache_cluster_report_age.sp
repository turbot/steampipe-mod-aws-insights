dashboard "elasticache_cluster_age_report" {

  title         = "AWS Elasticache Age Report"
  documentation = file("./dashboards/elasticache/docs/elasticache_cluster_report_age.md")

  tags = merge(local.elasticache_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.elasticache_cluster_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.elasticache_cluster_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.elasticache_cluster_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.elasticache_cluster_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.elasticache_cluster_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.elasticache_cluster_1_year_count
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Cluster ID" {
      href = "${dashboard.elasticache_cluster_detail.url_path}?input.elasticache_cluster_arn={{.ARN | @uri}}"
    }

    query = query.elasticache_cluster_age_table
  }

}

query "elasticache_cluster_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_elasticache_cluster
    where
      cache_cluster_create_time > now() - '1 days' :: interval;
  EOQ
}

query "elasticache_cluster_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_elasticache_cluster
    where
      cache_cluster_create_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "elasticache_cluster_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_elasticache_cluster
    where
      cache_cluster_create_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "elasticache_cluster_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_elasticache_cluster
    where
      cache_cluster_create_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "elasticache_cluster_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_elasticache_cluster
    where
      cache_cluster_create_time <= now() - '1 year' :: interval;
  EOQ
}

query "elasticache_cluster_age_table" {
  sql = <<-EOQ
    select
      e.cache_cluster_id as "Cluster ID",
      e.tags ->> 'Name' as "Name",
      now()::date - e.cache_cluster_create_time::date as "Age in Days",
      e.cache_cluster_create_time as "Create Time",
      e.cache_cluster_status as "Status",
      a.title as "Account",
      e.account_id as "Account ID",
      e.region as "Region",
      e.arn as "ARN"
    from
      aws_elasticache_cluster as e,
      aws_account as a
    where
      e.account_id = a.account_id
    order by
      e.cache_cluster_id;
  EOQ
}
