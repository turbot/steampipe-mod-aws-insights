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

      with "instances" {
        sql = <<-EOQ
          select
            i.arn as instance_arn
          from
            aws_ec2_instance as i,
            jsonb_array_elements(network_interfaces) as eni
          where
            eni ->> 'NetworkInterfaceId' = $1;
        EOQ

        args = [self.input.network_interface_id.value]
      }

      with "security_groups" {
        sql = <<-EOQ
          select
           distinct sg ->> 'GroupId' as security_group_id
          from
            aws_ec2_network_interface as eni,
            jsonb_array_elements(groups) as sg
          where
            eni.network_interface_id = $1;
        EOQ

        args = [self.input.network_interface_id.value]
      }

      with "subnets" {
        sql = <<-EOQ
          select
            subnet_id as subnet_id
          from
            aws_ec2_network_interface
          where
            network_interface_id = $1;
        EOQ

        args = [self.input.network_interface_id.value]
      }

      with "eips" {
        sql = <<-EOQ
          select
            arn as eip_arn
          from
            aws_vpc_eip
          where
            network_interface_id = $1;
        EOQ

        args = [self.input.network_interface_id.value]
      }

      with "vpcs" {
        sql = <<-EOQ
          select
            vpc_id as vpc_id
          from
            aws_ec2_network_interface
          where
            network_interface_id = $1;
        EOQ

        args = [self.input.network_interface_id.value]
      }

      with "flow_logs" {
        sql = <<-EOQ
          select
            flow_log_id as flow_log_id
          from
            aws_vpc_flow_log
          where
            resource_id = $1;
        EOQ

        args = [self.input.network_interface_id.value]
      }

      nodes = [
        node.aws_ec2_network_interface_nodes,
        node.aws_ec2_instance_nodes,
        node.vpc_security_group,
        node.vpc_subnet,
        node.vpc,
        node.aws_vpc_eip_nodes,
        node.aws_vpc_flow_log_nodes,

        node.aws_ec2_network_interface_vpc_nat_gateway_nodes
      ]

      edges = [
        edge.aws_ec2_network_interface_to_vpc_eip_edges,
        edge.aws_ec2_instance_to_ec2_network_interface_edges,
        edge.aws_ec2_network_interface_to_vpc_security_group_edges,
        edge.aws_ec2_network_interface_to_vpc_subnet_edges,
        edge.aws_vpc_subnet_to_vpc_edges,
        edge.aws_ec2_network_interface_to_vpc_flow_log_edges,

        edge.aws_vpc_nat_gateway_to_ec2_network_interface_edges
      ]

      args = {
        eni_ids            = [self.input.network_interface_id.value]
        instance_arns      = with.instances.rows[*].instance_arn
        security_group_ids = with.security_groups.rows[*].security_group_id
        subnet_ids         = with.subnets.rows[*].subnet_id
        eip_arns           = with.eips.rows[*].eip_arn
        vpc_ids            = with.vpcs.rows[*].vpc_id
        flow_log_ids       = with.flow_logs.rows[*].flow_log_id

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

node "aws_ec2_network_interface_nodes" {
  category = category.aws_ec2_network_interface

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
      network_interface_id = any($1 ::text[]);
  EOQ

  param "eni_ids" {}
}

edge "aws_ec2_network_interface_to_vpc_eip_edges" {
  title = "eip"

  sql = <<-EOQ
    select
      eni_ids as from_id,
      eip_arns as to_id
    from
      unnest($1::text[]) as eni_ids,
      unnest($2::text[]) as eip_arns
  EOQ

  param "eni_ids" {}
  param "eip_arns" {}
}


edge "aws_ec2_network_interface_to_vpc_security_group_edges" {
  title = "security group"

  sql = <<-EOQ
    select
      eni_ids as from_id,
      security_group_ids as to_id
    from
      unnest($1::text[]) as eni_ids,
      unnest($2::text[]) as security_group_ids
  EOQ

  param "eni_ids" {}
  param "security_group_ids" {}
}

edge "aws_ec2_network_interface_to_vpc_subnet_edges" {
  title = "subnet"

  sql = <<-EOQ
    select
      coalesce(
        security_group_ids,
        eni_ids
      ) as from_id,
      subnet_ids as to_id
    from
      unnest($1::text[]) as eni_ids,
      unnest($2::text[]) as subnet_ids,
      unnest($3::text[]) as security_group_ids
  EOQ

  param "eni_ids" {}
  param "subnet_ids" {}
  param "security_group_ids" {}
}


edge "aws_vpc_subnet_to_vpc_edges" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet_ids as from_id,
      vpc_ids as to_id
    from
      unnest($1::text[]) as subnet_ids,
      unnest($2::text[]) as vpc_ids
  EOQ

  param "subnet_ids" {}
  param "vpc_ids" {}
}


edge "aws_ec2_network_interface_to_vpc_flow_log_edges" {
  title = "flow log"

  sql = <<-EOQ
   select
      eni_ids as from_id,
      flow_log_ids as to_id
    from
      unnest($1::text[]) as eni_ids,
      unnest($2::text[]) as flow_log_ids
  EOQ

  param "eni_ids" {}
  param "flow_log_ids" {}
}

node "aws_ec2_network_interface_vpc_nat_gateway_nodes" {
  category = category.aws_vpc_nat_gateway

  sql = <<-EOQ
    select
      n.arn as id,
      n.title as title,
      jsonb_build_object(
        'ARN', n.arn,
        'NAT Gateway ID', n.nat_gateway_id,
        'State', n.state,
        'Account ID', n.account_id,
        'Region', n.region
      ) as properties
    from
      aws_vpc_nat_gateway as n,
      jsonb_array_elements(nat_gateway_addresses) as a
    where
      a ->> 'NetworkInterfaceId' = any($1);
  EOQ

  param "eni_ids" {}
}

edge "aws_vpc_nat_gateway_to_ec2_network_interface_edges" {
  title = "eni"

  sql = <<-EOQ
    select
      n.arn as from_id,
      a ->> 'NetworkInterfaceId' as to_id
    from
      aws_vpc_nat_gateway as n,
      jsonb_array_elements(nat_gateway_addresses) as a
    where
      a ->> 'NetworkInterfaceId' = any($1);
  EOQ

  param "eni_ids" {}
}
