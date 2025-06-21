dashboard "vpc_inventory_report" {

  title         = "AWS VPC Inventory Report"
  documentation = file("./dashboards/vpc/docs/vpc_report_inventory.md")

  tags = merge(local.vpc_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.vpc_count
      width = 2
    }

  }

  table {
    column "VPC ID" {
      href = "${dashboard.vpc_detail.url_path}?input.vpc_id={{.'VPC ID' | @uri}}"
    }

    query = query.vpc_inventory_table
  }

}

query "vpc_inventory_table" {
  sql = <<-EOQ
    select
      v.vpc_id as "VPC ID",
      v.cidr_block as "CIDR Block",
      v.instance_tenancy as "Instance Tenancy",
      v.is_default as "Is Default VPC",
      v.state as "State",
      v.tags as "Tags",
      v.arn as "ARN",
      v.account_id as "Account ID",
      a.title as "Account",
      v.region as "Region"
    from
      aws_vpc as v
      left join aws_account as a on v.account_id = a.account_id
    order by
      v.vpc_id;
  EOQ
} 