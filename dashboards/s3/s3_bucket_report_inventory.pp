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
    column "name" {
      href = "${dashboard.s3_bucket_detail.url_path}?input.bucket_arn={{.arn | @uri}}"
    }

    column "sp_connection_name" {
      display = "none"
    }

    column "sp_ctx" {
      display = "none"
    }

    column "_ctx" {
      display = "none"
    }

    column "title" {
      display = "none"
    }

    column "akas" {
      display = "none"
    }

    column "partition" {
      display = "none"
    }

    query = query.s3_bucket_inventory_table
  }

}

query "s3_bucket_inventory_table" {
  sql = <<-EOQ
    select
      b.*,
      a.title as "account_name"
    from
      aws_s3_bucket as b,
      aws_account as a
    where
      b.account_id = a.account_id
    order by
      b.name;
  EOQ
} 