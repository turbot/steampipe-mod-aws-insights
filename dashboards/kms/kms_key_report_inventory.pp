dashboard "kms_key_inventory_report" {

  title         = "AWS KMS Key Inventory Report"
  documentation = file("./dashboards/kms/docs/kms_key_report_inventory.md")

  tags = merge(local.kms_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.kms_key_count
      width = 2
    }

  }

  table {
    column "Key ID" {
      href = "${dashboard.kms_key_detail.url_path}?input.key_arn={{.'ARN' | @uri}}"
    }

    query = query.kms_key_inventory_table
  }

}

query "kms_key_inventory_table" {
  sql = <<-EOQ
    select
      k.id as "Key ID",
      k.creation_date as "Creation Date",
      k.key_state as "Key State",
      k.enabled as "Enabled",
      k.key_rotation_enabled as "Key Rotation Enabled",
      k.tags as "Tags",
      k.arn as "ARN",
      k.account_id as "Account ID",
      a.title as "Account",
      k.region as "Region"
    from
      aws_kms_key as k
      left join aws_account as a on k.account_id = a.account_id
    order by
      k.creation_date desc;
  EOQ
} 