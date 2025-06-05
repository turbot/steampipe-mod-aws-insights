dashboard "ec2_instance_inventory_report" {

  title         = "AWS EC2 Instance Inventory Report"
  documentation = file("./dashboards/ec2/docs/ec2_instance_report_inventory.md")

  tags = merge(local.ec2_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.ec2_instance_count
      width = 2
    }

  }

  table {
    column "Instance ID" {
      href = "${dashboard.ec2_instance_detail.url_path}?input.instance_arn={{.arn | @uri}}"
    }

    query = query.ec2_instance_inventory_table
  }

}

query "ec2_instance_inventory_table" {
  sql = <<-EOQ
    select
      i.instance_id as "Instance ID",
      i.title as "Name",
      i.launch_time as "Launch Time",
      i.instance_type as "Instance Type",
      i.disable_api_termination as "Disable API Termination",
      i.image_id as "Image ID",
      i.subnet_id as "Subnet ID",
      i.vpc_id as "VPC ID",
      i.tags as "Tags",
      i.arn as "ARN",
      i.account_id as "Account ID",
      a.title as "Account",
      i.region as "Region"
    from
      aws_ec2_instance as i,
      aws_account as a
    where
      i.account_id = a.account_id
    order by
      i.instance_id;
  EOQ
} 