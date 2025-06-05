dashboard "s3_bucket_inventory_report_minimal" {

  title         = "AWS S3 Bucket Inventory Report Minimal"
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
      href = "${dashboard.s3_bucket_detail.url_path}?input.bucket_arn={{.arn | @uri}}"
    }

    query = query.s3_bucket_inventory_table_minimal
  }

}

query "s3_bucket_inventory_table_minimal" {
  sql = <<-EOQ
    select
      b.title as "Name",
      b.creation_date as "Creation Date",
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