dashboard "cloudtrail_trail_inventory_report" {

  title         = "AWS CloudTrail Trail Inventory Report"
  documentation = file("./dashboards/cloudtrail/docs/cloudtrail_trail_report_inventory.md")

  tags = merge(local.cloudtrail_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.cloudtrail_trail_count
      width = 2
    }

  }

  table {
    column "Name" {
      href = "${dashboard.cloudtrail_trail_detail.url_path}?input.trail_arn={{.'ARN' | @uri}}"
    }

    query = query.cloudtrail_trail_inventory_table
  }

}

query "cloudtrail_trail_inventory_table" {
  sql = <<-EOQ
    select
      t.name as "Name",
      t.created_timestamp as "Created Timestamp",
      t.is_multi_region_trail as "Multi Region Trail",
      t.is_organization_trail as "Organization Trail",
      t.is_logging as "Logging",
      t.log_file_validation_enabled as "Log File Validation",
      t.kms_key_id as "KMS Key ID",
      t.s3_bucket_name as "S3 Bucket",
      t.home_region as "Home Region",
      t.tags as "Tags",
      t.arn as "ARN",
      t.account_id as "Account ID",
      a.title as "Account",
      t.region as "Region"
    from
      aws_cloudtrail_trail as t
      left join aws_account as a on t.account_id = a.account_id
    where
      t.region = t.home_region
    order by
      t.name;
  EOQ
} 