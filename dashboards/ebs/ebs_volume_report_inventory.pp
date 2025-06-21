dashboard "ebs_volume_inventory_report" {

  title         = "AWS EBS Volume Inventory Report"
  documentation = file("./dashboards/ebs/docs/ebs_volume_report_inventory.md")

  tags = merge(local.ebs_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.ebs_volume_count
      width = 2
    }

  }

  table {
    column "Volume ID" {
      href = "${dashboard.ebs_volume_detail.url_path}?input.volume_id={{.'Volume ID' | @uri}}"
    }

    query = query.ebs_volume_inventory_table
  }

}

query "ebs_volume_inventory_table" {
  sql = <<-EOQ
    select
      v.volume_id as "Volume ID",
      v.create_time as "Create Time",
      v.size as "Size (GB)",
      v.volume_type as "Volume Type",
      v.state as "State",
      v.encrypted as "Encrypted",
      v.kms_key_id as "KMS Key ID",
      v.iops as "IOPS",
      v.multi_attach_enabled as "Multi Attach Enabled",
      v.tags as "Tags",
      v.arn as "ARN",
      v.account_id as "Account ID",
      acc.title as "Account",
      v.region as "Region"
    from
      aws_ebs_volume as v
      left join aws_account as acc on v.account_id = acc.account_id
    order by
      v.volume_id;
  EOQ
} 