dashboard "rds_db_cluster_inventory_report" {

  title         = "AWS RDS DB Cluster Inventory Report"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_report_inventory.md")

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.rds_db_cluster_count
      width = 2
    }

  }

  table {
    column "DB Cluster Identifier" {
      href = "${dashboard.rds_db_cluster_detail.url_path}?input.db_cluster_arn={{.'ARN' | @uri}}"
    }

    query = query.rds_db_cluster_inventory_table
  }

}

query "rds_db_cluster_inventory_table" {
  sql = <<-EOQ
    select
      c.db_cluster_identifier as "DB Cluster Identifier",
      c.create_time as "Create Time",
      c.engine as "Engine",
      c.engine_version as "Engine Version",
      c.status as "Status",
      c.availability_zones as "Availability Zones",
      jsonb_array_length(c.members) as "Number of Instances",
      c.tags as "Tags",
      c.arn as "ARN",
      c.account_id as "Account ID",
      a.title as "Account",
      c.region as "Region"
    from
      aws_rds_db_cluster as c
      left join aws_account as a on c.account_id = a.account_id
    order by
      c.db_cluster_identifier;
  EOQ
} 