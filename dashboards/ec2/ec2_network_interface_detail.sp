dashboard "aws_ec2_network_interface_detail" {
  title         = "AWS EC2 Network Interface Detail"
  documentation = file("./dashboards/ec2/docs/ec2_eni_detail.md")

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
      query = query.aws_ec2_eni_public_ip
      args = {
        network_interface_id = self.input.network_interface_id.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_eni_type
      args = {
        network_interface_id = self.input.network_interface_id.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_eni_delete_on_termination
      args = {
        network_interface_id = self.input.network_interface_id.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_eni_status
      args = {
        network_interface_id = self.input.network_interface_id.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_eni_attachment_status
      args = {
        network_interface_id = self.input.network_interface_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_ec2_network_interface_node,
        node.aws_ec2_network_interface_from_ec2_instance_node,
        node.aws_ec2_network_interface_to_vpc_security_group_node,
        node.aws_ec2_network_interface_to_vpc_subnet_node,
        node.aws_ec2_network_interface_to_vpc_node
      ]

      edges = [
        edge.aws_ec2_network_interface_from_ec2_instance_edge,
        edge.aws_ec2_network_interface_to_vpc_security_group_edge,
        edge.aws_ec2_network_interface_to_security_group_to_subnet_edge,
        edge.aws_ec2_network_interface_to_security_group_subnet_to_vpc_edge
      ]

      args = {
        network_interface_id = self.input.network_interface_id.value
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 2
      query = query.aws_ec2_eni_overview
      args = {
        network_interface_id = self.input.network_interface_id.value
      }
    }

    table {
      title = "Tags"
      width = 3
      query = query.aws_ec2_eni_tags
      args = {
        network_interface_id = self.input.network_interface_id.value
      }
    }

    container {
      width = 7

      table {
        title = "Associations"
        query = query.aws_ec2_eni_association_details
        args = {
          network_interface_id = self.input.network_interface_id.value
        }
        column "eip_alloc_arn" {
          display = "none"
        }
        column "Allocation ID" {
          href = "/aws_insights.dashboard.aws_vpc_eip_detail?input.eip_arn={{.'eip_alloc_arn' | @uri}}"
        }
      }

      table {
        title = "Private IP Addresses"
        query = query.aws_ec2_eni_private_ip
        args = {
          network_interface_id = self.input.network_interface_id.value
        }
      }
    }

  }
}

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

query "aws_ec2_eni_status" {
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

  param "network_interface_id" {}
}

query "aws_ec2_eni_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      initcap(interface_type) as value
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1
  EOQ

  param "network_interface_id" {}
}

query "aws_ec2_eni_attachment_status" {
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

  param "network_interface_id" {}
}

query "aws_ec2_eni_delete_on_termination" {
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

  param "network_interface_id" {}
}

query "aws_ec2_eni_public_ip" {
  sql = <<-EOQ
    select
      'Public IP' as label,
      case when association_public_ip is null then 'None' else host(association_public_ip) end as value
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1
  EOQ

  param "network_interface_id" {}
}

query "aws_ec2_eni_private_ip" {
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

  param "network_interface_id" {}
}

query "aws_ec2_eni_association_details" {
  sql = <<-EOQ
    select
      eni.association_allocation_id "Allocation ID",
      eni.association_public_ip as "Public IP Address",
      eni.association_carrier_ip as "Carrier IP",
      eni.association_customer_owned_ip as "Customer Owned IP",
      eni.association_id as "Association ID",
      eni.association_ip_owner_id as "IP Owner ID",
      eni.association_public_dns_name as "Public DNS Name",
      eip_alloc.arn as "eip_alloc_arn"
    from
      aws_ec2_network_interface eni
    left join aws_vpc_eip eip_alloc on
      eip_alloc.allocation_id = eni.association_allocation_id
      and eip_alloc.association_id = eni.association_id
    where
      eni.network_interface_id = $1
      and eni.association_allocation_id is not null;
  EOQ

  param "network_interface_id" {}
}

query "aws_ec2_eni_overview" {
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

  param "network_interface_id" {}
}

query "aws_ec2_eni_tags" {
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

  param "network_interface_id" {}
}

category "aws_ec2_network_interface_no_link" {
  color = "orange"
  icon  = local.aws_ec2_network_interface_icon
}

node "aws_ec2_network_interface_node" {
  category = category.aws_ec2_network_interface_no_link

  sql = <<-EOQ
    select
      network_interface_id as id,
      title as title,
      jsonb_build_object(
        'ID', network_interface_id,
        'Interface Type', interface_type,
        'Status', status,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1;
  EOQ

  param "network_interface_id" {}
}

node "aws_ec2_network_interface_from_ec2_instance_node" {
  category = category.aws_ec2_instance

  sql = <<-EOQ
    select
      instance.instance_id as id,
      instance.title as title,
      jsonb_build_object(
        'ID', instance.instance_id,
        'ARN', instance.arn,
        'State', instance.instance_state,
        'Public IP Address', instance.private_ip_address,
        'Account ID', instance.account_id,
        'Region', instance.region
      ) as properties
    from
      aws_ec2_network_interface as eni
      left join aws_ec2_instance as instance on eni.attached_instance_id = instance.instance_id
    where
      eni.network_interface_id = $1;
  EOQ

  param "network_interface_id" {}
}

edge "aws_ec2_network_interface_from_ec2_instance_edge" {
  title = "eni"

  sql = <<-EOQ
    select
      instance.instance_id as from_id,
      eni.network_interface_id as to_id,
      jsonb_build_object(
        'Attachment ID', attachment_id,
        'Attachment Status', attachment_status,
        'Attachment Time', attachment_time,
        'Delete on Instance Termination', delete_on_instance_termination,
        'Device Index', device_index
      ) as properties
    from
      aws_ec2_network_interface as eni
      left join aws_ec2_instance as instance on eni.attached_instance_id = instance.instance_id
    where
      eni.network_interface_id = $1;
  EOQ

  param "network_interface_id" {}
}

node "aws_ec2_network_interface_to_vpc_security_group_node" {
  category = category.aws_vpc_security_group

  sql = <<-EOQ
    select
      sg ->> 'GroupId' as id,
      sg ->> 'GroupName' as title,
      jsonb_build_object(
        'Group ID', sg ->> 'GroupId',
        'Name', sg ->> 'GroupName',
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_network_interface as eni,
      jsonb_array_elements(groups) as sg
    where
      eni.network_interface_id = $1;
  EOQ

  param "network_interface_id" {}
}

edge "aws_ec2_network_interface_to_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      eni.network_interface_id as from_id,
      sg ->> 'GroupId' as to_id
    from
      aws_ec2_network_interface as eni,
      jsonb_array_elements(groups) as sg
    where
      eni.network_interface_id = $1;
  EOQ

  param "network_interface_id" {}
}

node "aws_ec2_network_interface_to_vpc_subnet_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      subnet.subnet_id as id,
      subnet.title as title,
      jsonb_build_object(
        'Subnet ID', subnet.subnet_id ,
        'VPC ID', subnet.vpc_id ,
        'CIDR Block', subnet.cidr_block,
        'AZ', subnet.availability_zone,
        'Account ID', subnet.account_id,
        'Region', subnet.region
      ) as properties
    from
      aws_ec2_network_interface as eni
      left join aws_vpc_subnet as subnet on eni.subnet_id = subnet.subnet_id
    where
      eni.network_interface_id = $1;
  EOQ

  param "network_interface_id" {}
}

edge "aws_ec2_network_interface_to_security_group_to_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      coalesce(
        sg ->> 'GroupId',
        network_interface_id
      ) as from_id,
      subnet.subnet_id as to_id
    from
      aws_ec2_network_interface as eni
      left join aws_vpc_subnet as subnet on eni.subnet_id = subnet.subnet_id
      left join jsonb_array_elements(eni.groups) as sg on true
    where
      eni.network_interface_id = $1;
  EOQ

  param "network_interface_id" {}
}

node "aws_ec2_network_interface_to_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      vpc.vpc_id as id,
      vpc.title as title,
      jsonb_build_object(
        'VPC ID', vpc.vpc_id,
        'Name', vpc.tags ->> 'Name',
        'CIDR Block', vpc.cidr_block,
        'Account ID', vpc.account_id,
        'Owner ID', vpc.owner_id,
        'Region', vpc.region
      ) as properties
    from
      aws_ec2_network_interface as eni
      left join aws_vpc as vpc on eni.vpc_id = vpc.vpc_id
    where
      eni.network_interface_id = $1;
  EOQ

  param "network_interface_id" {}
}

edge "aws_ec2_network_interface_to_security_group_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      vpc_id as to_id
    from
      aws_ec2_network_interface
    where
      network_interface_id = $1;
  EOQ

  param "network_interface_id" {}
}
