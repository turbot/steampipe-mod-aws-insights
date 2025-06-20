dashboard "ebs_snapshot_inventory_report" {

  title         = "AWS EBS Snapshot Inventory Report"
  documentation = file("./dashboards/ebs/docs/ebs_snapshot_report_inventory.md")

  tags = merge(local.ebs_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.ebs_snapshot_count
      width = 2
    }

  }

  table {
    column "Snapshot ID" {
      href = "${dashboard.ebs_snapshot_detail.url_path}?input.snapshot_id={{.'Snapshot ID' | @uri}}"
    }

    query = query.ebs_snapshot_inventory_table
  }

}

query "ebs_snapshot_inventory_table" {
  sql = <<-EOQ
    select
      s.snapshot_id as "Snapshot ID",
      s.start_time as "Start Time",
      s.volume_id as "Volume ID",
      s.volume_size as "Size (GB)",
      s.state as "State",
      s.progress as "Progress",
      s.encrypted as "Encrypted",
      s.kms_key_id as "KMS Key ID",
      s.description as "Description",
      s.tags as "Tags",
      s.arn as "ARN",
      s.account_id as "Account ID",
      a.title as "Account",
      s.region as "Region"
    from
      aws_ebs_snapshot as s
      left join aws_account as a on s.account_id = a.account_id
    order by
      s.snapshot_id;
  EOQ
} 