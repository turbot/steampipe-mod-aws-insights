dashboard "ebs_snapshot_age_report" {

  title         = "AWS EBS Snapshot Age Report"
  documentation = file("./dashboards/ebs/docs/ebs_snapshot_report_age.md")

  tags = merge(local.ebs_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.ebs_snapshot_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.ebs_snapshot_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.ebs_snapshot_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.ebs_snapshot_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.ebs_snapshot_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.ebs_snapshot_1_year_count
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Snapshot ID" {
      href = "${dashboard.ebs_snapshot_detail.url_path}?input.ebs_snapshot_arn={{.ARN | @uri}}"
    }

    query = query.ebs_snapshot_age_table
  }

}

query "ebs_snapshot_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_ebs_snapshot
    where
      start_time > now() - '1 days' :: interval;
  EOQ
}

query "ebs_snapshot_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_ebs_snapshot
    where
      start_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "ebs_snapshot_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_ebs_snapshot
    where
      start_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "ebs_snapshot_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_ebs_snapshot
    where
      start_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "ebs_snapshot_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_ebs_snapshot
    where
      start_time <= now() - '1 year' :: interval;
  EOQ
}

query "ebs_snapshot_age_table" {
  sql = <<-EOQ
    select
      s.snapshot_id as "Snapshot ID",
      s.tags ->> 'Name' as "Name",
      now()::date - s.start_time::date as "Age in Days",
      s.start_time as "Create Time",
      s.state as "State",
      a.title as "Account",
      s.account_id as "Account ID",
      s.region as "Region",
      s.arn as "ARN"
    from
      aws_ebs_snapshot as s,
      aws_account as a
    where
      s.account_id = a.account_id
    order by
      s.snapshot_id;
  EOQ
}

