dashboard "ebs_snapshot_public_access_report" {

  title         = "AWS EBS Snapshot Public Access Report"
  documentation = file("./dashboards/ebs/docs/ebs_snapshot_report_public_access.md")

  tags = merge(local.ebs_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      query = query.ebs_snapshot_count
      width = 2
    }

    card {
      query = query.ebs_snapshot_public_count
      width = 2
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
      href = "${dashboard.ebs_snapshot_detail.url_path}?input.ebs_snapshot_id={{.'Snapshot ID' | @uri}}"
    }

    query = query.ebs_snapshot_public_table
  }

}

query "ebs_snapshot_public_table" {
  sql = <<-EOQ
    select
      s.snapshot_id as "Snapshot ID",
      s.tags ->> 'Name' as "Name",
      case when s.create_volume_permissions @> '[{"Group": "all"}]' then 'Enabled' else null end as "Public Access",
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
