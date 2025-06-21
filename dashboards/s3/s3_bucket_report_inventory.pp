dashboard "s3_bucket_inventory_report" {

  title         = "AWS S3 Bucket Inventory Report"
  documentation = file("./dashboards/s3/docs/s3_bucket_report_inventory.md")

  tags = merge(local.s3_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.s3_bucket_count
      width = 2
    }

  }

  table {
    column "Name" {
      href = "${dashboard.s3_bucket_detail.url_path}?input.bucket_arn={{.'ARN' | @uri}}"
    }

    query = query.s3_bucket_inventory_table
  }

}

query "s3_bucket_inventory_table" {
  sql = <<-EOQ
    select
      b.title as "Name",
      b.creation_date as "Creation Date",
      b.bucket_policy_is_public as "Bucket Policy is Public",
      b.versioning_enabled as "Versioning",
      b.lifecycle_rules as "Lifecycle Rules",
      b.logging as "Logging",
      b.policy as "Policy",
      b.tags as "Tags",
      b.arn as "ARN",
      b.account_id as "Account ID",
      a.title as "Account",
      b.region as "Region"
    from
      aws_s3_bucket as b,
      aws_account as a
    where
      b.account_id = a.account_id
    order by
      b.name;
  EOQ
}
