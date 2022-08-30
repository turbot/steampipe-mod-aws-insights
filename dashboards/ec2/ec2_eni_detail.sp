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
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_ec2_eni_relationships_graph
      args = {
        network_interface_id = self.input.network_interface_id.value
      }
      category "aws_ec2_network_interface" {
        icon = local.aws_ec2_network_interface_icon
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
        title = "IP Addresses and Associations"
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
      pvt_ip_addrs ->> 'PrivateIpAddress' as "Private IP Address",
      pvt_ip_addrs -> 'Association' ->> 'PublicIp' as "Public IP Address",
      pvt_ip_addrs -> 'Association' ->> 'CarrierIp' as "Carrier IP",
      pvt_ip_addrs -> 'Association' ->> 'CustomerOwnedIp' as "Customer Owned IP",
      pvt_ip_addrs -> 'Association' ->> 'IpOwnerId' as "IP Owner ID",
      pvt_ip_addrs -> 'Association' ->> 'AllocationId' as "Allocation ID",
      pvt_ip_addrs -> 'Association' ->> 'AssociationId' as "Association ID",
      eip_alloc.arn as "eip_alloc_arn"
    from
      aws_ec2_network_interface eni,
      jsonb_array_elements(eni.private_ip_addresses) as pvt_ip_addrs
    left join aws_vpc_eip eip_alloc on
      eip_alloc.allocation_id = pvt_ip_addrs -> 'Association' ->> 'AllocationId'
      and eip_alloc.association_id = pvt_ip_addrs -> 'Association' ->> 'AssociationId'
    where
      eni.network_interface_id = $1
      and pvt_ip_addrs ->> 'Association' is not null
  EOQ

  param "network_interface_id" {}
}

query "aws_ec2_eni_overview" {
  sql = <<-EOQ
    select
      network_interface_id as "ID",
      title as "Title",
      attachment_time as "Attachment Time",
      private_dns_name as "Private DNS Name",
      association_public_dns_name as "Public DNS Name",
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

query "aws_ec2_eni_relationships_graph" {
  sql = <<-EOQ
    with network_interface as
    (
      select
        network_interface_id,
        title,
        attached_instance_id,
        subnet_id,
        vpc_id,
        groups,
        account_id,
        region
      from
        aws_ec2_network_interface
      where
        network_interface_id = $1
    )

    -- Resource (node)
    select
      null as from_id,
      null as to_id,
      network_interface_id as id,
      title as title,
      'aws_ec2_network_interface' as category,
      jsonb_build_object(
        'ID', network_interface.network_interface_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      network_interface

    -- To EC2 Instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      instance.instance_id as id,
      instance.title as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'ID', instance.instance_id,
        'ARN', instance.arn,
        'State', instance.instance_state,
        'Public DNS Name', instance.public_dns_name,
        'Public IP Address', instance.private_ip_address,
        'Private DNS Name', instance.private_dns_name,
        'Private IP Address', instance.public_ip_address,
        'Account ID', instance.account_id,
        'Region', instance.region
      ) as properties
    from
      network_interface
    left join
      aws_ec2_instance as instance
      on network_interface.attached_instance_id = instance.instance_id

    -- To EC2 Instances (edge)
    union all
    select
      network_interface.network_interface_id as from_id,
      instance.instance_id as to_id,
      null as id,
      'attached to' as title,
      'ec2_network_interface_to_ec2_instance' as category,
      jsonb_build_object(
        'Account ID', instance.account_id
      ) as properties
    from
      network_interface
      left join
        aws_ec2_instance as instance
        on network_interface.attached_instance_id = instance.instance_id

    -- To VPC security groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      sg ->> 'GroupId' as id,
      sg ->> 'GroupName' as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'Group ID', sg ->> 'GroupId',
        'Name', sg ->> 'GroupName',
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      network_interface,
      jsonb_array_elements(groups) as sg

    -- To VPC security groups (edge)
    union all
    select
      network_interface.network_interface_id as from_id,
      sg ->> 'GroupId' as to_id,
      null as id,
      'security groups' as title,
      'ec2_network_interface_to_vpc_security_group' as category,
      jsonb_build_object(
        'Account ID', account_id
      ) as properties
    from
      network_interface,
      jsonb_array_elements(groups) as sg

    -- To VPC subnets (node)
    union all
    select
      null as from_id,
      null as to_id,
      subnet.subnet_id as id,
      subnet.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'Name', subnet.tags ->> 'Name',
        'Subnet ID', subnet.subnet_id ,
        'VPC ID', subnet.vpc_id ,
        'CIDR Block', subnet.cidr_block,
        'AZ', subnet.availability_zone,
        'Account ID', subnet.account_id,
        'Region', subnet.region
      ) as properties
    from
      network_interface
    left join
      aws_vpc_subnet as subnet
      on network_interface.subnet_id = subnet.subnet_id

    -- To VPC subnets (edge)
    union all
    select
      network_interface.network_interface_id as from_id,
      subnet.subnet_id as to_id,
      null as id,
      'launched in' as title,
      'ec2_network_interface_to_vpc_subnet' as category,
      jsonb_build_object(
        'Account ID', network_interface.account_id,
        'Name', subnet.tags ->> 'Name',
        'Subnet ID', subnet.subnet_id,
        'State', subnet.state
      ) as properties
    from
      network_interface
      left join
        aws_vpc_subnet as subnet
        on network_interface.subnet_id = subnet.subnet_id

    -- To VPCs (node)
    union all
    select
      null as from_id,
      null as to_id,
      vpc.vpc_id as id,
      vpc.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ID', vpc.vpc_id,
        'Name', vpc.tags ->> 'Name',
        'CIDR Block', vpc.cidr_block,
        'Account ID', vpc.account_id,
        'Owner ID', vpc.owner_id,
        'Region', vpc.region
      ) as properties
    from
      network_interface
      left join
        aws_vpc as vpc
        on network_interface.vpc_id = vpc.vpc_id

    -- To VPCs (edge)
    union all
    select
      network_interface.network_interface_id as from_id,
      vpc.vpc_id as to_id,
      null as id,
      'vpc' as title,
      'ec2_instance_to_vpc' as category,
      jsonb_build_object(
        'ID', vpc.vpc_id,
        'Name', vpc.tags ->> 'Name',
        'CIDR Block', vpc.cidr_block,
        'Account ID', vpc.account_id,
        'Owner ID', vpc.owner_id,
        'Region', vpc.region
      ) as properties
    from
      network_interface
      left join
        aws_vpc as vpc
        on network_interface.vpc_id = vpc.vpc_id

    order by
      category,
      from_id,
      to_id;

  EOQ

  param "network_interface_id" {}
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
