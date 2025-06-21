dashboard "rds_db_instance_inventory_report" {

  title         = "AWS RDS DB Instance Inventory Report"
  documentation = file("./dashboards/rds/docs/rds_db_instance_report_inventory.md")

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.rds_db_instance_count
      width = 2
    }

  }

  table {
    column "DB Instance Identifier" {
      href = "${dashboard.rds_db_instance_detail.url_path}?input.db_instance_arn={{.'ARN' | @uri}}"
    }

    query = query.rds_db_instance_inventory_table
  }

}

query "rds_db_instance_inventory_table" {
  sql = <<-EOQ
    select
      i.db_instance_identifier as "DB Instance Identifier",
      i.create_time as "Create Time",
      i.class as "Instance Class",
      i.engine as "Engine",
      i.engine_version as "Engine Version",
      i.status as "Status",
      i.availability_zone as "Availability Zone",
      i.storage_type as "Storage Type",
      i.allocated_storage as "Allocated Storage (GB)",
      i.tags as "Tags",
      i.arn as "ARN",
      i.account_id as "Account ID",
      a.title as "Account",
      i.region as "Region"
    from
      aws_rds_db_instance as i
      left join aws_account as a on i.account_id = a.account_id
    order by
      i.db_instance_identifier;
  EOQ
} 