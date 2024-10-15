dashboard "ec2_network_interface_detail" {
  title         = "AWS EC2 Network Interface Detail"
  documentation = file("./dashboards/ec2/docs/ec2_network_interface_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "network_interface_id" {
    title = "Select a Network Interface:"
    query = query.network_interface_id
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ec2_network_interface_public_ip
      args  = [self.input.network_interface_id.value]
    }

    card {
      width = 2
      query = query.ec2_network_interface_type
      args  = [self.input.network_interface_id.value]
    }

    card {
      width = 2
      query = query.ec2_network_interface_delete_on_termination
      args  = [self.input.network_interface_id.value]
    }

    card {
      width = 2
      query = query.ec2_network_interface_status
      args  = [self.input.network_interface_id.value]
    }

    card {
      width = 2
      query = query.ec2_network_interface_attachment_status
      args  = [self.input.network_interface_id.value]
    }

  }

  with "ec2_instances_for_ec2_network_interface" {
    query = query.ec2_instances_for_ec2_network_interface
    args  = [self.input.network_interface_id.value]
  }

  with "vpc_eips_for_ec2_network_interface" {
    query = query.vpc_eips_for_ec2_network_interface
    args  = [self.input.network_interface_id.value]
  }

  with "vpc_flow_logs_for_ec2_network_interface" {
    query = query.vpc_flow_logs_for_ec2_network_interface
    args  = [self.input.network_interface_id.value]
  }

  with "vpc_nat_gateways_for_ec2_network_interface" {
    query = query.vpc_nat_gateways_for_ec2_network_interface
    args  = [self.input.network_interface_id.value]
  }

  with "vpc_security_groups_for_ec2_network_interface" {
    query = query.vpc_security_groups_for_ec2_network_interface
    args  = [self.input.network_interface_id.value]
  }

  with "vpc_subnets_for_ec2_network_interface" {
    query = query.vpc_subnets_for_ec2_network_interface
    args  = [self.input.network_interface_id.value]
  }

  with "vpc_vpcs_for_ec2_network_interface" {
    query = query.vpc_vpcs_for_ec2_network_interface
    args  = [self.input.network_interface_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.ec2_instance
        args = {
          ec2_instance_arns = with.ec2_instances_for_ec2_network_interface.rows[*].instance_arn
        }
      }

      node {
        base = node.ec2_network_interface
        args = {
          ec2_network_interface_ids = [self.input.network_interface_id.value]
        }
      }

      node {
        base = node.vpc_eip
        args = {
          vpc_eip_arns = with.vpc_eips_for_ec2_network_interface.rows[*].eip_arn
        }
      }

      node {
        base = node.vpc_flow_log
        args = {
          vpc_flow_log_ids = with.vpc_flow_logs_for_ec2_network_interface.rows[*].flow_log_id
        }
      }

      node {
        base = node.vpc_nat_gateway
        args = {
          vpc_nat_gateway_arns = with.vpc_nat_gateways_for_ec2_network_interface.rows[*].gateway_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_ec2_network_interface.rows[*].security_group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_ec2_network_interface.rows[*].subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_ec2_network_interface.rows[*].vpc_id
        }
      }

      edge {
        base = edge.ec2_instance_to_ec2_network_interface
        args = {
          ec2_instance_arns = with.ec2_instances_for_ec2_network_interface.rows[*].instance_arn
        }
      }

      edge {
        base = edge.ec2_network_interface_to_vpc_eip
        args = {
          ec2_network_interface_ids = [self.input.network_interface_id.value]
        }
      }

      edge {
        base = edge.ec2_network_interface_to_vpc_flow_log
        args = {
          ec2_network_interface_ids = [self.input.network_interface_id.value]
        }
      }

      edge {
        base = edge.ec2_network_interface_to_vpc_security_group
        args = {
          ec2_network_interface_ids = [self.input.network_interface_id.value]
        }
      }

      edge {
        base = edge.ec2_network_interface_to_vpc_subnet
        args = {
          ec2_network_interface_ids = [self.input.network_interface_id.value]
        }
      }

      edge {
        base = edge.vpc_nat_gateway_to_ec2_network_interface
        args = {
          ec2_network_interface_ids = [self.input.network_interface_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_ec2_network_interface.rows[*].subnet_id
        }
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 2
      query = query.ec2_network_interface_overview
      args  = [self.input.network_interface_id.value]
    }

    table {
      title = "Tags"
      width = 3
      query = query.ec2_network_interface_tags
      args  = [self.input.network_interface_id.value]
    }

    container {
      width = 7

      table {
        title = "Associations"
        query = query.ec2_network_interface_association_details
        args  = [self.input.network_interface_id.value]
        column "eip_alloc_arn" {
          display = "none"
        }
        column "Allocation ID" {
          href = "/aws_insights.dashboard.vpc_eip_detail?input.eip_arn={{.'eip_alloc_arn' | @uri}}"
        }
      }

      table {
        title = "Private IP Addresses"
        query = query.ec2_network_interface_private_ip
        args  = [self.input.network_interface_id.value]
      }
    }

  }
}

# Input queries

query "network_interface_id" {
  sql = <<-EOQ
    select
      title as label,
      network_interface_id as value,
      json_build_object(
        'type', interface_type,
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_ec2_network_interface
    order by
      title;
  EOQ
}

# With queries

query "ec2_instances_for_ec2_network_interface" {
  sql = <<-EOQ
    select
      i.arn as instance_arn
    from
      aws_ec2_instance as i,
      jsonb_array_elements(network_interfaces) as eni
    where
      eni ->> 'NetworkInterfaceId' = $1;
  EOQ
}

query "vpc_eips_for_ec2_network_interface" {
  sql = <<-EOQ
    select
      arn as eip_arn
    from
      aws_vpc_eip
    where
      network_interface_id = $1;
  EOQ
}

query "vpc_flow_logs_for_ec2_network_interface" {
  sql = <<-EOQ
    select
      flow_log_id as flow_log_id
    from
      aws_vpc_flow_log
    where
      resource_id = $1;
  EOQ
}

query "vpc_nat_gateways_for_ec2_network_interface" {
  sql = <<-EOQ
    select
      arn as gateway_arn
    from
      aws_vpc_nat_gateway,
      jsonb_array_elements(nat_gateway_addresses) as a
    where
      a ->> 'NetworkInterfaceId' = $1;
  EOQ
}

query "vpc_security_groups_for_ec2_network_interface" {
  sql = <<-EOQ
    select
      distinct sg ->> 'GroupId' as security_group_id
    from
      aws_ec2_network_interface as eni,
      jsonb_array_elements(groups) as sg
    where
      eni.network_interface_id = $1;
  EOQ
}

query "vpc_subnets_for_ec2_network_interface" {
  sql = <<-EOQ
    select
      subnet_id as subnet_id
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1;
  EOQ
}

query "vpc_vpcs_for_ec2_network_interface" {
  sql = <<-EOQ
    select
      vpc_id as vpc_id
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1;
  EOQ
}

# Card queries

query "ec2_network_interface_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      case when status = 'in-use' then 'In Use' else initcap(status) end as value,
      case when status = 'available' then 'alert' else 'ok' end as type
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1
  EOQ
}

query "ec2_network_interface_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      initcap(interface_type) as value
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1
  EOQ
}

query "ec2_network_interface_attachment_status" {
  sql = <<-EOQ
    select
      'Attachment Status' as label,
      case when attachment_status = 'attached' then 'Attached' else 'Detached' end as value,
      case when attachment_status = 'attached' then 'ok' else 'alert' end as type
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1
  EOQ
}

query "ec2_network_interface_delete_on_termination" {
  sql = <<-EOQ
    select
      'Delete on Instance Terminate' as label,
      case
        when interface_type = 'interface'
        then
          case when delete_on_instance_termination then 'Enabled' else 'Disabled' end
        else
          'Not Applicable'
      end as value,
      case
        when interface_type = 'interface'
        then
          case when delete_on_instance_termination then 'ok' else 'alert' end
        else
          ''
      end as type
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1;
  EOQ
}

query "ec2_network_interface_public_ip" {
  sql = <<-EOQ
    select
      'Public IP' as label,
      case when association_public_ip is null then 'None' else host(association_public_ip) end as value
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1
  EOQ
}

# Other detail page queries

query "ec2_network_interface_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      attachment_time as "Attachment Time",
      private_dns_name as "Private DNS Name",
      mac_address as "MAC Address",
      availability_zone as "Availibility Zone",
      region as "Region",
      account_id as "Account ID"
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1
  EOQ
}

query "ec2_network_interface_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ec2_network_interface,
      jsonb_array_elements(tags_src) as tag
    where
      network_interface_id = $1
    order by
      tag ->> 'Key';
    EOQ
}

query "ec2_network_interface_private_ip" {
  sql = <<-EOQ
    select
      pvt_ip_addr ->> 'PrivateIpAddress' as "IP Address",
      pvt_ip_addr ->> 'Primary' as "Primary"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addr
    where
      eni.network_interface_id = $1
    order by
      -- primary first
      pvt_ip_addr ->> 'Primary' desc
  EOQ
}

query "ec2_network_interface_association_details" {
  sql = <<-EOQ
    select
      eni.association_allocation_id "Allocation ID",
      eni.association_public_ip as "Public IP Address",
      eni.association_carrier_ip as "Carrier IP",
      eni.association_customer_owned_ip as "Customer Owned IP",
      eni.association_id as "Association ID",
      eni.association_ip_owner_id as "IP Owner ID",
      eni.association_public_dns_name as "Public DNS Name",
      eip_alloc.arn as "EIP Alloc ARN"
    from
      aws_ec2_network_interface eni
    left join aws_vpc_eip eip_alloc on
      eip_alloc.allocation_id = eni.association_allocation_id
      and eip_alloc.association_id = eni.association_id
    where
      eni.network_interface_id = $1
      and eni.association_allocation_id is not null;
  EOQ
}
