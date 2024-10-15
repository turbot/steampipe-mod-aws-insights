dashboard "emr_cluster_age_report" {

  title         = "AWS EMR Cluster Age Report"
  documentation = file("./dashboards/emr/docs/emr_cluster_report_age.md")

  tags = merge(local.emr_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.emr_cluster_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.emr_cluster_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.emr_cluster_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.emr_cluster_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.emr_cluster_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.emr_cluster_1_year_count
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
      href = "${dashboard.emr_cluster_detail.url_path}?input.emr_cluster_arn={{.ARN | @uri}}"
    }

    query = query.emr_cluster_age_table
  }

}

query "emr_cluster_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_emr_cluster
    where
      (status -> 'Timeline' ->> 'CreationDateTime')::timestamp > now() - '1 days' :: interval;
  EOQ
}

query "emr_cluster_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_emr_cluster
    where
      (status -> 'Timeline' ->> 'CreationDateTime')::timestamp between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "emr_cluster_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_emr_cluster
    where
      (status -> 'Timeline' ->> 'CreationDateTime')::timestamp between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "emr_cluster_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_emr_cluster
    where
      (status -> 'Timeline' ->> 'CreationDateTime')::timestamp between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "emr_cluster_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_emr_cluster
    where
      (status -> 'Timeline' ->> 'CreationDateTime')::timestamp <= now() - '1 year' :: interval;
  EOQ
}

query "emr_cluster_age_table" {
  sql = <<-EOQ
    select
      c.id as "Cluster ID",
      c.name as "Name",
      now()::date - (c.status -> 'Timeline' ->> 'CreationDateTime')::date as "Age in Days",
      c.status -> 'Timeline' ->> 'CreationDateTime' as "Creation Time",
      c.state as "State",
      a.title as "Account",
      c.account_id as "Account ID",
      c.region as "Region",
      c.cluster_arn as "ARN"
    from
      aws_emr_cluster as c,
      aws_account as a
    where
      c.account_id = a.account_id
    order by
      c.status -> 'Timeline' ->> 'CreationDateTime',
      c.id;
  EOQ
}
