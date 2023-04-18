#---------------------------------------------------------------------------------------------------------
# Dashboard: ec2_instance_inventory_dashboard
#---------------------------------------------------------------------------------------------------------

dashboard "ec2_instance_inventory_dashboard" {

  title         = "AWS EC2 Inventory"
  documentation = file("./dashboards/ec2/docs/ec2_instance_inventory_dashboard.md")

  tags = merge(local.ec2_common_tags, {
    type = "Inventory"
  })

  # Cards
  container {
    card {
      title = "AWS Account with the most VMs"
      query = query.ec2_instance_top_by_account
      type  = "info"
      width = 3
    }

    card {
      title = "Most used EC2 type"
      query = query.ec2_instance_top_by_type
      type  = "info"
      width = 3
    }

    card {
      title = "Most used region"
      query = query.ec2_instance_top_by_region
      type  = "info"
      width = 3
    }

    card {
      title = "Most used Availability Zone"
      query = query.ec2_instance_top_by_zone
      type  = "info"
      width = 3
    }
  }


  # Details
  container {
    title = "Details"

    table {
      query = query.ec2_instance_details
      width = 12

      column "ARN" {
        display = "none"
      }

      column "Instance ID" {
        href = "/aws_insights.dashboard.ec2_instance_detail?input.instance_arn={{ .'ARN' | @uri }}"
      }
    }


  }

}

#---------------------------------------------------------------------------------------------------------
# Queries
#---------------------------------------------------------------------------------------------------------

# Cards
query "ec2_instance_top_by_account" {
  sql = <<-EOQ
    Select
      account_id as label,
      COUNT(*) as value
    from
        aws_ec2_instance
    group by
        account_id
    order by
        value DESC
    limit
        1
  EOQ
}

query "ec2_instance_top_by_type" {
  sql = <<-EOQ
    Select
      instance_type as label,
      COUNT(*) as value
    from
        aws_ec2_instance
    group by
        instance_type
    order by
        value DESC
    limit
        1
  EOQ
}

query "ec2_instance_top_by_region" {
  sql = <<-EOQ
    Select
      region as label,
      COUNT(*) as value
    from
        aws_ec2_instance
    group by
        region
    order by
        value DESC
    limit
        1
  EOQ
}

query "ec2_instance_top_by_zone" {
  sql = <<-EOQ
    Select
      placement_availability_zone as label,
      COUNT(*) as value
    from
        aws_ec2_instance
    group by
        placement_availability_zone
    order by
        value DESC
    limit
        1
  EOQ
}


# Details
query "ec2_instance_details" {
  sql = <<-EOQ
    select 
      'EC2' as "Resource",
      acc.title as "AWS Account",
      ec2.title as "Instance Name",
      ec2.instance_id as "Instance ID",
      ec2.instance_state as "Status",
      ec2.instance_type as "Instance Type",
      ec2.region as "Region",
      ec2.placement_availability_zone as "Availability Zone",
      ec2.launch_time as "Launch Time",
      ec2.vpc_id as "VPC ID",
      ec2.subnet_id as "Subnet ID",
      ec2.private_ip_address as "Private IP",
      ec2.public_ip_address as "Public IP",
      ec2.ebs_optimized as "EBS Optimized",
      ec2.image_id as "Image ID",
      ec2.key_name as "Key Name",
      ec2.arn as "ARN"
    from 
      aws_ec2_instance as ec2
      join aws_account as acc on ec2.account_id = acc.account_id
  EOQ
}