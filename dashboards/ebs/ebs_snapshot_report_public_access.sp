dashboard "aws_ebs_snapshot_public_access_report" {

  title = "AWS EBS Snapshot Public Access Report"

  tags = merge(local.ebs_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      sql   = query.aws_ebs_snapshot_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ebs_snapshot_public_count.sql
      width = 2
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    sql = query.aws_ebs_snapshot_public_table.sql
  }

}

query "aws_ebs_snapshot_public_table" {
  sql = <<-EOQ
    select
      s.tags ->> 'Name' as "Name",
      s.snapshot_id as "Snapshot",
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

  EOQ
}
