dashboard "aws_vpc_detail" {

  title         = "AWS VPC Detail"
  documentation = file("./dashboards/vpc/docs/vpc_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "vpc_id" {
    title = "Select a VPC:"
    sql   = query.aws_vpc_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_vpc_num_ips_for_vpc
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

    card {
      width = 2
      query = query.aws_subnet_count_for_vpc
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_is_default
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

    card {
      width = 2
      query = query.aws_flow_logs_count_for_vpc
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

  }


container {
  graph {
      title = "Relationships"
      width = 12
      type  = "graph"
      nodes = [
        node.aws_vpc_node,
        node.aws_vpc_az_node,
        node.aws_vpc_vpc_subnet_node,
        node.aws_vpc_igw_node,
        node.aws_vpc_az_route_table,
        node.aws_vpc_vcp_endpoint_node,
        node.aws_vpc_transit_gateway_node,
        node.aws_vpc_nat_gateway_node,
        node.aws_vpc_vpn_gateway_node,
        node.aws_vpc_vpc_security_group_node,

        node.aws_vpc_ec2_instance_node,
        node.aws_vpc_lambda_function_node,
        node.aws_vpc_alb_node,
        node.aws_vpc_nlb_node,
        node.aws_vpc_security_elb_node,
        node.aws_vpc_gwlbnode,
        node.aws_vpc_rds_instance_node,
        node.aws_vpc_redshift_cluster_node,
        node.aws_vpc_fsx_filesystem_node,
        node.aws_vpc_s3_access_point_node,

        node.aws_vpc_peered_vpc_node,
      ]

      edges = [
        edge.aws_vpc_az_edge,
        edge.aws_vpc_az_subnet_edge,
        edge.aws_vpc_igw_edge,
        edge.aws_vpc_subnet_route_table_edge,
        edge.aws_vpc_vpc_route_table_edge,
        edge.aws_vpc_subnet_endpoint_edge,
        edge.aws_vpc_transit_gateway_edge,
        edge.aws_vpc_subnet_nat_gateway_edge,
        edge.aws_vpc_vpn_gateway_edge,
        edge.aws_vpc_security_group_edge,

        edge.aws_vpc_subnet_instance_edge,
        edge.aws_vpc_subnet_lambda_edge,
        edge.aws_vpc_subnet_alb_edge,
        edge.aws_vpc_subnet_nlb_edge,
        edge.aws_vpc_subnet_elb_edge,
        edge.aws_vpc_subnet_gwlb_edge,
        edge.aws_vpc_subnet_rds_edge,
        edge.aws_vpc_subnet_redshift_edge,
        edge.aws_vpc_subnet_fxs_edge,
        edge.aws_vpc_s3_access_point_edge,

        edge.aws_vpc_peered_vpc_edge
      ]
      
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }
    

    
  }


  container {

    container {

      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_vpc_overview
        args = {
          vpc_id = self.input.vpc_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_vpc_tags
        args = {
          vpc_id = self.input.vpc_id.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "CIDR Blocks"
        query = query.aws_vpc_cidr_blocks
        args = {
          vpc_id = self.input.vpc_id.value
        }
      }

      table {
        title = "DHCP Options"
        query = query.aws_vpc_dhcp_options
        args = {
          vpc_id = self.input.vpc_id.value
        }
      }

    }

  }

  container {

    title = "Subnets"

    chart {
      title = "Subnets by AZ"
      type  = "column"
      width = 4
      query = query.aws_vpc_subnet_by_az
      args = {
        vpc_id = self.input.vpc_id.value
      }

    }

    table {
      query = query.aws_vpc_subnets_for_vpc
      width = 6
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

  }

  container {

    title = "Routing"


    flow {
      nodes = [
        node.aws_vpc_routing_vpc_node,
        node.aws_vpc_routing_subnet_node,
        node.aws_vpc_routing_cidr_node,
        node.aws_vpc_routing_gateway_node
      ]

      edges = [
        edge.aws_vpc_routing_subnet_vpc_to_cidr_edge,
        edge.aws_vpc_routing_cidr_to_gateway_edge
      ]

      args = {
        vpc_id = self.input.vpc_id.value
      }

    }

    table {
      title = "Route Tables"
      query = query.aws_vpc_route_tables_for_vpc
      width = 6
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

    table {
      title = "Routes"
      query = query.aws_vpc_routes_for_vpc
      width = 6
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

  }


  container {

    title = "Peering Connections"

    table {
      title = "Peering Connections"
      query = query.aws_vpc_peers_for_vpc
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

  }

  container {

    title = "NACLs"


    flow {
      base  = flow.nacl_flow
      title = "Ingress NACLs"
      width = 6
      query = query.aws_ingress_nacl_for_vpc_sankey
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }


    flow {
      base  = flow.nacl_flow
      title = "Egress NACLs"
      width = 6
      query = query.aws_egress_nacl_for_vpc_sankey
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }


  }

  container {

    title = "Gateways & Endpoints"

    table {
      title = "VPC Endpoints"

      query = query.aws_vpc_endpoints_for_vpc
      width = 6
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

    table {
      title = "Gateways"
      query = query.aws_vpc_gateways_for_vpc
      width = 6
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

  }

  container {

    title = "Security Groups"

    table {
      query = query.aws_vpc_security_groups_for_vpc
      width = 12
      args = {
        vpc_id = self.input.vpc_id.value
      }

      column "Group Name" {
        href = "${dashboard.aws_vpc_security_group_detail.url_path}?input.security_group_id={{.'Group ID' | @uri}}"
      }
    }

  }

}


flow "nacl_flow" {
  width = 6
  type  = "sankey"


  category "deny" {
    color = "alert"
  }

  category "allow" {
    color = "ok"
  }

}

query "aws_vpc_input" {
  sql = <<-EOQ
    select
      title as label,
      vpc_id as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'vpc_id', vpc_id
      ) as tags
    from
      aws_vpc
    order by
      title;
  EOQ
}

query "aws_subnet_count_for_vpc" {
  sql = <<-EOQ
    select
      'Subnets' as label,
      count(*) as value,
      case when count(*) > 0 then 'ok' else 'alert' end as type
    from
      aws_vpc_subnet
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_is_default" {
  sql = <<-EOQ
    select
      'Default VPC' as label,
      case when not is_default then 'ok' else 'Default VPC' end as value,
      case when not is_default then 'ok' else 'alert' end as type
    from
      aws_vpc
    where
      vpc_id = $1;
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_num_ips_for_vpc" {
  sql = <<-EOQ
    with cidrs as (
      select
        b ->> 'CidrBlock' as cidr_block,
        masklen(( b ->> 'CidrBlock')::cidr)  as "Mask Length",
        power(2, 32 - masklen( (b ->> 'CidrBlock'):: cidr)) as num_ips
      from
        aws_vpc,
        jsonb_array_elements(cidr_block_association_set) as b
      where vpc_id = $1
    )
    select
      sum(num_ips) as "IP Addresses"
    from
      cidrs

  EOQ

  param "vpc_id" {}
}

query "aws_flow_logs_count_for_vpc" {
  sql = <<-EOQ
    select
      'Flow Logs' as label,
      count(*) as value,
      case when count(*) > 0 then 'ok' else 'alert' end as type
    from
      aws_vpc_flow_log
    where resource_id = reverse(split_part(reverse($1), '/', 1));
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_subnets_for_vpc" {
  sql = <<-EOQ
    with subnets as (
      select
        subnet_id,
        tags,
        cidr_block,
        availability_zone,
        available_ip_address_count,
        power(2, 32 - masklen(cidr_block :: cidr)) -1 as raw_size
      from
        aws_vpc_subnet
      where
        vpc_id = $1
    )
    select
      subnet_id as "Subnet ID",
      tags ->> 'Name' as "Name",
      cidr_block as "CIDR Block",
      availability_zone as "Availbility Zone",
      available_ip_address_count as "Available IPs",
      power(2, 32 - masklen(cidr_block :: cidr)) -1 as "Total IPs",
      round(100 * (available_ip_address_count / (raw_size))::numeric, 2) as "% Free"
    from
      subnets
    order by
      subnet_id;
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_security_groups_for_vpc" {
  sql = <<-EOQ
    select
      group_name as "Group Name",
      group_id as "Group ID",
      description as "Description"
    from
      aws_vpc_security_group
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_endpoints_for_vpc" {
  sql = <<-EOQ
    select
      vpc_endpoint_id as "VPC Endpoint ID",
      tags ->> 'Name' as "Name",
      service_name as "Service Name"
    from
      aws_vpc_endpoint
    where
      vpc_id = $1
    order by
      vpc_endpoint_id;
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_route_tables_for_vpc" {
  sql = <<-EOQ
    select
      route_table_id as "Route Table ID",
      tags ->> 'Name' as "Name"
    from
      aws_vpc_route_table
    where
      vpc_id = $1
    order by
      route_table_id;
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_routes_for_vpc" {
  sql = <<-EOQ
    select
      route_table_id as "Route Table ID",
      tags ->> 'Name' as "Name",
      r ->> 'State' as "State",
      case
        when r ->> 'GatewayId' is not null then r ->> 'GatewayId'
        when r ->> 'InstanceId' is not null then r ->> 'InstanceId'
        when r ->> 'NatGatewayId' is not null then r ->> 'NatGatewayId'
        when r ->> 'LocalGatewayId' is not null then r ->> 'LocalGatewayId'
        when r ->> 'CarrierGatewayId' is not null then r ->> 'CarrierGatewayId'
        when r ->> 'TransitGatewayId' is not null then r ->> 'TransitGatewayId'
        when r ->> 'VpcPeeringConnectionId' is not null then r ->> 'VpcPeeringConnectionId'
        when r ->> 'DestinationPrefixListId' is not null then r ->> 'DestinationPrefixListId'
        when r ->> 'DestinationIpv6CidrBlock' is not null then r ->> 'DestinationIpv6CidrBlock'
        when r ->> 'EgressOnlyInternetGatewayId' is not null then r ->> 'EgressOnlyInternetGatewayId'
        when r ->> 'NetworkInterfaceId' is not null then r ->> 'NetworkInterfaceId'
        when r ->> 'CoreNetworkArn' is not null then r ->> 'CoreNetworkArn'
        when r ->> 'InstanceOwnerId' is not null then r ->> 'InstanceOwnerId'
      end as "Gateway",
      r ->> 'DestinationCidrBlock' as "Destination CIDR",
      case
        when a ->> 'Main' = 'true' then vpc_id
        when a ->> 'SubnetId' is not null then  a->> 'SubnetId'
        else '??'
      end as "Associated To"
    from
      aws_vpc_route_table,
      jsonb_array_elements(routes) as r,
      jsonb_array_elements(associations) as a
    where
      vpc_id = $1
    order by
      route_table_id,
      "Associated To"
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_peers_for_vpc" {
  sql = <<-EOQ
    select
      id as "ID",
      tags ->> 'Name' as "Name",
      status_code as "Status Code",
      requester_owner_id as "Request Owner ID",
      requester_region as "Requester Region",
      requester_vpc_id as "Requester VPC ID",
      requester_cidr_block as "Requester CIDR Block",
      accepter_owner_id "Accepter Owner ID",
      accepter_region "Accepter Region",
      accepter_vpc_id "Accepter VPC ID",
      accepter_cidr_block as "Accepter CIDR Block"
    from
      aws_vpc_peering_connection
    where
      requester_vpc_id = $1
      or accepter_vpc_id = $1
    order by
      id
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_gateways_for_vpc" {
  sql = <<-EOQ
    select
      internet_gateway_id as "ID",
      tags ->> 'Name' as "Name",
      'aws_vpc_internet_gateway' as "Type",
      a ->> 'State' as "State"
    from
      aws_vpc_internet_gateway,
      jsonb_array_elements(attachments) as a
     where
      a ->> 'VpcId' = reverse(split_part(reverse($1), '/', 1))
    union all
    select
      id as "ID",
      tags ->> 'Name' as "Name",
      'aws_vpc_egress_only_internet_gateway' as "Type",
      a ->> 'State' as "State"
    from
      aws_vpc_egress_only_internet_gateway,
      jsonb_array_elements(attachments) as a
     where
      a ->> 'VpcId' = reverse(split_part(reverse($1), '/', 1))
    union all
    select
      vpn_gateway_id as "ID",
      tags ->> 'Name' as "Name",
      'aws_vpc_vpn_gateway' as "Type",
      a ->> 'State' as "State"
    from
      aws_vpc_vpn_gateway,
      jsonb_array_elements(vpc_attachments) as a
     where
      a ->> 'VpcId' = reverse(split_part(reverse($1), '/', 1))
    union all
    select
      nat_gateway_id as "ID",
      tags ->> 'Name' as "Name",
      'aws_vpc_nat_gateway' as "Type",
      state as "State"
    from
      aws_vpc_nat_gateway
     where
       vpc_id = $1
  EOQ

  param "vpc_id" {}
}

query "aws_ingress_nacl_for_vpc_sankey" {
  sql = <<-EOQ

    with aces as (
      select
        arn,
        title,
        network_acl_id,
        is_default,
        e -> 'Protocol' as protocol_number,
        e ->> 'CidrBlock' as ipv4_cidr_block,
        e ->> 'Ipv6CidrBlock' as ipv6_cidr_block,
        coalesce(e ->> 'CidrBlock', e ->> 'Ipv6CidrBlock') as cidr_block,
        e -> 'PortRange' -> 'To' as to_port,
        e -> 'PortRange' -> 'From' as from_port,
        e ->> 'RuleAction' as rule_action,
        e -> 'RuleNumber' as rule_number,
        to_char((e->>'RuleNumber')::numeric, 'fm00000')  as rule_num_padded,

        -- e -> 'IcmpTypeCode' as icmp_type_code,
        e -> 'IcmpTypeCode' -> 'Code' as icmp_code,
        e -> 'IcmpTypeCode' -> 'Type' as icmp_type,

        e -> 'Protocol' as protocol_number,
        e -> 'Egress' as is_egress,

        case when e ->> 'RuleAction' = 'allow' then 'Allow ' else 'Deny ' end ||
          case
              when e->>'Protocol' = '-1' then 'All Traffic'
              when e->>'Protocol' = '1'  and e->'IcmpTypeCode' is null then 'All ICMP'
              when e->>'Protocol' = '58'  and e->'IcmpTypeCode' is null then 'All ICMPv6'
              when e->>'Protocol' = '6'  and e->'PortRange' is null then 'All TCP'
              when e->>'Protocol' = '17' and e->'PortRange' is null then 'All UDP'
              when e->>'Protocol' = '6' and e->'PortRange'->>'From' = '0' and e->'PortRange'->>'To' = '65535'
                then 'All TCP'
              when e->>'Protocol' = '17' and e->'PortRange'->>'From' = '0' and e->'PortRange'->>'To' = '65535'
                then  'All UDP'
              when e->>'Protocol' = '1'  and e->'IcmpTypeCode' is not null
                then concat('ICMP Type ', e->'IcmpTypeCode'->>'Type', ', Code ',  e->'IcmpTypeCode'->>'Code')
              when e->>'Protocol' = '58'  and e->'IcmpTypeCode' is not null
                then concat('ICMPv6 Type ', e->'IcmpTypeCode'->>'Type', ', Code ',  e->'IcmpTypeCode'->>'Code')
              when e->>'Protocol' = '6' and e->'PortRange'->>'To'  = e->'PortRange'->>'From'
                then  concat(e->'PortRange'->>'To', '/TCP')
              when e->>'Protocol' = '17' and e->'PortRange'->>'To'  = e->'PortRange'->>'From'
                then  concat(e->'PortRange'->>'To', '/UDP')
              when e->>'Protocol' = '6' and e->'PortRange'->>'From' <> e->'PortRange' ->> 'To'
                then  concat(e->'PortRange'->>'To', '-', e->'PortRange'->>'From', '/TCP')
              when e->>'Protocol' = '17' and e->'PortRange'->>'From' <> e->'PortRange'->>'To'
                then  concat(e->'PortRange'->>'To', '-', e->'PortRange'->>'From', '/UDP')
              else concat('Procotol: ', e->>'Protocol')
        end as rule_description,

        a ->> 'SubnetId' as subnet_id,
        a ->> 'NetworkAclAssociationId' as nacl_association_id
      from
        aws_vpc_network_acl,
        jsonb_array_elements(entries) as e,
        jsonb_array_elements(associations) as a
      where
        vpc_id = $1
        and not (e -> 'Egress')::boolean

    )

    -- CIDR Nodes
    select
      distinct cidr_block as id,
      cidr_block as title,
      'cidr_block' as category,
      null as from_id,
      null as to_id
    from aces

    -- Rule Nodes
    union select
      concat(network_acl_id, '_', rule_num_padded) as id,
      concat(rule_number, ': ', rule_description) as title,
      'rule' as category,
      null as from_id,
      null as to_id
    from aces

    -- ACL Nodes
    union select
      distinct network_acl_id as id,
      network_acl_id as title,
      'nacl' as category,
      null as from_id,
      null as to_id
    from aces

    -- Subnet node
    union select
      distinct subnet_id as id,
      subnet_id as title,
      'subnet' as category,
      null as from_id,
      null as to_id
    from aces

    -- ip -> rule edge
    union select
      null as id,
      null as title,
      rule_action as category,
      cidr_block as from_id,
      concat(network_acl_id, '_', rule_num_padded) as to_id
    from aces

    -- rule -> NACL edge
    union select
      null as id,
      null as title,
      rule_action as category,
      concat(network_acl_id, '_', rule_num_padded) as from_id,
      network_acl_id as to_id
    from aces

    -- nacl -> subnet edge
    union select
      null as id,
      null as title,
      'attached' as category,
      network_acl_id as from_id,
      subnet_id as to_id
    from aces

  EOQ

  param "vpc_id" {}
}

query "aws_egress_nacl_for_vpc_sankey" {
  sql = <<-EOQ

    with aces as (
      select
        arn,
        title,
        network_acl_id,
        is_default,
        e -> 'Protocol' as protocol_number,
        e ->> 'CidrBlock' as ipv4_cidr_block,
        e ->> 'Ipv6CidrBlock' as ipv6_cidr_block,
        coalesce(e ->> 'CidrBlock', e ->> 'Ipv6CidrBlock') as cidr_block,
        e -> 'PortRange' -> 'To' as to_port,
        e -> 'PortRange' -> 'From' as from_port,
        e ->> 'RuleAction' as rule_action,
        e -> 'RuleNumber' as rule_number,
        to_char((e->>'RuleNumber')::numeric, 'fm00000')  as rule_num_padded,

        -- e -> 'IcmpTypeCode' as icmp_type_code,
        e -> 'IcmpTypeCode' -> 'Code' as icmp_code,
        e -> 'IcmpTypeCode' -> 'Type' as icmp_type,

        e -> 'Protocol' as protocol_number,
        e -> 'Egress' as is_egress,

        case when e ->> 'RuleAction' = 'allow' then 'Allow ' else 'Deny ' end ||
          case
              when e->>'Protocol' = '-1' then 'All Traffic'
              when e->>'Protocol' = '1'  and e->'IcmpTypeCode' is null then 'All ICMP'
              when e->>'Protocol' = '58'  and e->'IcmpTypeCode' is null then 'All ICMPv6'
              when e->>'Protocol' = '6'  and e->'PortRange' is null then 'All TCP'
              when e->>'Protocol' = '17' and e->'PortRange' is null then 'All UDP'
              when e->>'Protocol' = '6' and e->'PortRange'->>'From' = '0' and e->'PortRange'->>'To' = '65535'
                then 'All TCP'
              when e->>'Protocol' = '17' and e->'PortRange'->>'From' = '0' and e->'PortRange'->>'To' = '65535'
                then  'All UDP'
              when e->>'Protocol' = '1'  and e->'IcmpTypeCode' is not null
                then concat('ICMP Type ', e->'IcmpTypeCode'->>'Type', ', Code ',  e->'IcmpTypeCode'->>'Code')
              when e->>'Protocol' = '58'  and e->'IcmpTypeCode' is not null
                then concat('ICMPv6 Type ', e->'IcmpTypeCode'->>'Type', ', Code ',  e->'IcmpTypeCode'->>'Code')
              when e->>'Protocol' = '6' and e->'PortRange'->>'To'  = e->'PortRange'->>'From'
                then  concat(e->'PortRange'->>'To', '/TCP')
              when e->>'Protocol' = '17' and e->'PortRange'->>'To'  = e->'PortRange'->>'From'
                then  concat(e->'PortRange'->>'To', '/UDP')
              when e->>'Protocol' = '6' and e->'PortRange'->>'From' <> e->'PortRange' ->> 'To'
                then  concat(e->'PortRange'->>'To', '-', e->'PortRange'->>'From', '/TCP')
              when e->>'Protocol' = '17' and e->'PortRange'->>'From' <> e->'PortRange'->>'To'
                then  concat(e->'PortRange'->>'To', '-', e->'PortRange'->>'From', '/UDP')
              else concat('Procotol: ', e->>'Protocol')
        end as rule_description,

        a ->> 'SubnetId' as subnet_id,
        a ->> 'NetworkAclAssociationId' as nacl_association_id
      from
        aws_vpc_network_acl,
        jsonb_array_elements(entries) as e,
        jsonb_array_elements(associations) as a
      where
        vpc_id = $1
        and (e -> 'Egress')::boolean
    )

    -- Subnet Nodes
    select
      distinct subnet_id as id,
      subnet_id as title,
      'subnet' as category,
      null as from_id,
      null as to_id,
      0 as depth
    from aces

    -- ACL Nodes
    union select
      distinct network_acl_id as id,
      network_acl_id as title,
      'nacl' as category,
      null as from_id,
      null as to_id,
      1 as depth

    from aces

    -- Rule Nodes
    union select
      concat(network_acl_id, '_', rule_num_padded) as id,
      concat(rule_number, ': ', rule_description) as title,
      'rule' as category,
      null as from_id,
      null as to_id,
      2 as depth
    from aces

    -- CIDR Nodes
    union select
      distinct cidr_block as id,
      cidr_block as title,
      'cidr_block' as category,
      null as from_id,
      null as to_id,
      3 as depth
    from aces

    -- subnet -> edge
    union select
      null as id,
      null as title,
      'attached' as category,
      subnet_id as from_id,
      network_acl_id as to_id,
      null as depth
    from aces

    -- NACL -> Rule edge
    union select
      null as id,
      null as title,
      rule_action as category,
      network_acl_id as from_id,
      concat(network_acl_id, '_', rule_num_padded) as to_id,
      null as depth
    from aces

    -- rule -> ip edge
    union select
      null as id,
      null as title,
      rule_action as category,
      concat(network_acl_id, '_', rule_num_padded) as from_id,
      cidr_block as to_id,
      null as depth
    from aces

  EOQ

  param "vpc_id" {}
}

query "aws_vpc_overview" {
  sql = <<-EOQ
    select
      vpc_id as "VPC ID",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_vpc
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_vpc,
      jsonb_array_elements(tags_src) as tag
    where
      vpc_id = $1
    order by
      tag ->> 'Key';
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_cidr_blocks" {
  sql = <<-EOQ
    select
      b ->> 'CidrBlock' as "CIDR Block",
      power(2, 32 - masklen( (b ->> 'CidrBlock'):: cidr)) as "Total IPs"
    from
      aws_vpc,
      jsonb_array_elements(cidr_block_association_set) as b
    where
      vpc_id = $1
    union all
    select
      b ->> 'Ipv6CidrBlock' as cidr_block,
      power(2, 128 - masklen( (b ->> 'Ipv6CidrBlock'):: cidr)) as num_ips
    from
      aws_vpc,
      jsonb_array_elements(ipv6_cidr_block_association_set) as b
    where
      vpc_id = $1;
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_dhcp_options" {
  sql = <<-EOQ
    select
      d.dhcp_options_id as "DHCP Options ID",
      d.tags ->> 'Name' as "Name",
      d.domain_name as "Domain Name",
      d.domain_name_servers as "Domain Name Servers",
      d.netbios_name_servers as "NetBIOS Name Servers",
      d.netbios_node_type "NetBIOS Node Type",
      d.ntp_servers as "NTP Servers"
    from
      aws_vpc as v,
      aws_vpc_dhcp_options as d
    where
      v.vpc_id = $1
      and v.dhcp_options_id = d.dhcp_options_id
    order by
      d.dhcp_options_id;
  EOQ

  param "vpc_id" {}
}

query "aws_vpc_subnet_by_az" {
  sql = <<-EOQ
    select
      availability_zone,
      count(*)
    from
      aws_vpc_subnet
    where
      vpc_id = $1
    group by
      availability_zone
    order by
      availability_zone
  EOQ

  param "vpc_id" {}
}

# query "aws_vpc_relationships_graph" {
#   sql = <<-EOQ
#     with vpc as
#     (
#       select
#         *
#       from
#         aws_vpc
#       where
#         vpc_id = $1
#     )

#     select
#       null as from_id,
#       null as to_id,
#       vpc_id as id,
#       title as title,
#       'aws_vpc' as category,
#       jsonb_build_object(
#         'VPC ID', vpc_id,
#         'ARN', arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       vpc

#   -- To Subnets (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       subnet_arn as id,
#       title as title,
#       'aws_vpc_subnet' as category,
#       jsonb_build_object(
#         'ARN', subnet_arn,
#         'Subnet ID', subnet_id,
#         'CIDR Block', cidr_block,
#         'IP Address Count', available_ip_address_count,
#         'Region', region,
#         'Account ID', account_id
#       ) as properties
#     from
#       aws_vpc_subnet
#     where
#       vpc_id = $1

#     -- To Subnets (Edge)
#     union all
#     select
#       v.vpc_id as from_id,
#       s.subnet_arn as to_id,
#       null as id,
#       'subnet' as title,
#       'vpc_subnet_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', s.subnet_arn,
#         'Account ID', s.account_id,
#         'Region', s.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_vpc_subnet as s on s.vpc_id = v.vpc_id

#     -- To Internet Gateways (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       internet_gateway_id as id,
#       title as title,
#       'aws_vpc_internet_gateway' as category,
#       jsonb_build_object(
#         'ID', internet_gateway_id,
#         'State', a ->> 'State',
#         'Region', region,
#         'Account ID', account_id
#       ) as properties
#     from
#       aws_vpc_internet_gateway,
#       jsonb_array_elements(attachments) as a
#     where
#       a ->> 'VpcId' = $1

#     -- To Internet Gateways (edge)
#     union all
#     select
#       v.vpc_id as from_id,
#       i.internet_gateway_id as to_id,
#       null as id,
#       'internet gateway' as title,
#       'vpc_internet_gateway_to_vpc' as category,
#       jsonb_build_object(
#         'ID', i.internet_gateway_id,
#         'Account ID', i.account_id,
#         'Region', i.region
#       ) as properties
#     from
#       vpc as v,
#       aws_vpc_internet_gateway as i,
#       jsonb_array_elements(attachments) as a
#     where
#       a ->> 'VpcId' = $1

#     -- To Route Tables (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       route_table_id as id,
#       title as title,
#       'aws_vpc_route_table' as category,
#       jsonb_build_object(
#         'ID', route_table_id,
#         'Region', region,
#         'Account ID', account_id
#       ) as properties
#     from
#       aws_vpc_route_table
#     where
#       vpc_id = $1

#     -- To Route Tables (edge)
#     union all
#     select
#       v.vpc_id as from_id,
#       rt.route_table_id as to_id,
#       null as id,
#       'route table' as title,
#       'vpc_route_table_to_vpc' as category,
#       jsonb_build_object(
#         'ID', rt.route_table_id,
#         'Account ID', rt.account_id,
#         'Region', rt.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_vpc_route_table as rt on rt.vpc_id = v.vpc_id

#     -- To VPC Endpoints (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       vpc_endpoint_id as id,
#       title as title,
#       'aws_vpc_endpoint' as category,
#       jsonb_build_object(
#         'ID', vpc_endpoint_id,
#         'Region', region,
#         'Account ID', account_id
#       ) as properties
#     from
#       aws_vpc_endpoint
#     where
#       vpc_id = $1

#     -- To VPC Endpoints (edge)
#     union all
#     select
#       v.vpc_id as from_id,
#       e.vpc_endpoint_id as to_id,
#       null as id,
#       'vpc endpoint' as title,
#       'vpc_endpoint_to_vpc' as category,
#       jsonb_build_object(
#         'ID', e.vpc_endpoint_id,
#         'Account ID', e.account_id,
#         'Region', e.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_vpc_endpoint as e on e.vpc_id = v.vpc_id

#     -- To Transit Gateways (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       g.transit_gateway_id as id,
#       g.title as title,
#       'aws_ec2_transit_gateway' as category,
#       jsonb_build_object(
#         'ID', g.transit_gateway_id,
#         'ARN', g.transit_gateway_arn,
#         'Attachment Id', t.transit_gateway_attachment_id,
#         'Association State', t.association_state,
#         'Region', g.region,
#         'Account ID', g.account_id
#       ) as properties
#     from
#       aws_ec2_transit_gateway_vpc_attachment as t
#       left join aws_ec2_transit_gateway as g on t.transit_gateway_id = g.transit_gateway_id
#     where
#       t.resource_id = $1 and resource_type = 'vpc'

#     -- To Transit Gateways (edge)
#     union all
#     select
#       v.vpc_id as from_id,
#       a.transit_gateway_id as to_id,
#       null as id,
#       'ec2 transit gateway' as title,
#       'c2_transit_gateway_to_vpc' as category,
#       jsonb_build_object(
#         'ID', a.transit_gateway_id,
#         'Account ID', a.account_id,
#         'Region', a.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_ec2_transit_gateway_vpc_attachment as a on a.resource_id = v.vpc_id

#     -- To NAT Gateways (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_vpc_nat_gateway' as category,
#       jsonb_build_object(
#         'ARN', arn,
#         'ID', nat_gateway_id,
#         'Region', region,
#         'Account ID', account_id
#       ) as properties
#     from
#       aws_vpc_nat_gateway
#     where
#       vpc_id = $1

#     -- To NAT Gateways (edge)
#     union all
#     select
#       v.vpc_id as from_id,
#       n.arn as to_id,
#       null as id,
#       'nat gateway' as title,
#       'vpc_nat_gateway_to_vpc' as category,
#       jsonb_build_object(
#         'ID', n.nat_gateway_id,
#         'Account ID', n.account_id,
#         'Region', n.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_vpc_nat_gateway as n on n.vpc_id = v.vpc_id

#     -- To VPN Gateways (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       vpn_gateway_id as id,
#       title as title,
#       'aws_vpc_vpn_gateway' as category,
#       jsonb_build_object(
#         'ID', vpn_gateway_id,
#         'Region', region,
#         'Account ID', account_id
#       ) as properties
#     from
#       aws_vpc_vpn_gateway,
#       jsonb_array_elements(vpc_attachments) as a
#     where
#       a ->> 'VpcId' = $1

#     -- To VPN Gateways (edge)
#     union all
#     select
#       v.vpc_id as from_id,
#       g.vpn_gateway_id as to_id,
#       null as id,
#       'vpn gateway' as title,
#       'vpn_gateway_to_vpc' as category,
#       jsonb_build_object(
#         'Account ID', g.account_id,
#         'Region', g.region
#       ) as properties
#     from
#       vpc as v,
#       aws_vpc_vpn_gateway as g,
#       jsonb_array_elements(vpc_attachments) as a
#     where
#       a ->> 'VpcId' = v.vpc_id

#   -- To Security Groups (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_vpc_security_group' as category,
#       jsonb_build_object(
#         'ARN', arn,
#         'Group ID', group_id,
#         'Region', region,
#         'Account ID', account_id
#       ) as properties
#     from
#       aws_vpc_security_group
#     where
#       vpc_id = $1

#     -- To Security Groups (edges)
#     union all
#     select
#       v.vpc_id as from_id,
#       sg.arn as to_id,
#       null as id,
#       'security group' as title,
#       'vpc_security_group_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', sg.arn,
#         'Account ID', sg.account_id,
#         'Region', sg.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_vpc_security_group as sg on sg.vpc_id = v.vpc_id

#     -- From EC2 Instances (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_ec2_instance' as category,
#       jsonb_build_object(
#         'ARN', i.arn,
#         'Account ID',i.account_id,
#         'Region', i.region
#       ) as properties
#     from
#       aws_ec2_instance as i
#     where
#       i.vpc_id  = $1

#     -- From EC2 Instances (edge)
#     union all
#     select
#       i.arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       'ec2 instance' as title,
#       'ec2_instance_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', i.arn,
#         'Account ID', i.account_id,
#         'Region', i.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_ec2_instance as i on i.vpc_id = v.vpc_id

#     -- From Lambda Functions (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_lambda_function' as category,
#       jsonb_build_object(
#         'ARN', arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       aws_lambda_function as l
#     where
#       l.vpc_id  = $1

#     -- From Lambda Functions (edge)
#     union all
#     select
#       l.arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       'lambda function ' as title,
#       'lambda_function_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', l.arn,
#         'Account ID', l.account_id,
#         'Region', l.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_lambda_function as l on l.vpc_id = v.vpc_id

#     -- From EC2 Application LBs (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_ec2_application_load_balancer' as category,
#       jsonb_build_object(
#         'ARN', arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       aws_ec2_application_load_balancer as a
#     where
#       a.vpc_id  = $1

#     -- From EC2 Application LBs (edge)
#     union all
#     select
#       a.arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       'ec2 application lb' as title,
#       'ec2_application_load_balancer_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', a.arn,
#         'Account ID', a.account_id,
#         'Region', a.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_ec2_application_load_balancer as a on a.vpc_id = v.vpc_id

#     -- From EC2 Network LBs (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_ec2_network_load_balancer' as category,
#       jsonb_build_object(
#         'ARN', arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       aws_ec2_network_load_balancer as n
#     where
#       n.vpc_id  = $1

#     -- From EC2 Network LBs (edge)
#     union all
#     select
#       n.arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       'network lb' as title,
#       'ec2_network_load_balancer_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', n.arn,
#         'Account ID', n.account_id,
#         'Region', n.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_ec2_network_load_balancer as n on n.vpc_id = v.vpc_id

#     -- From EC2 Classic LBs (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_ec2_classic_load_balancer' as category,
#       jsonb_build_object(
#         'ARN', arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       aws_ec2_classic_load_balancer as c
#     where
#       c.vpc_id  = $1

#     -- From EC2 Classic LBs (edge)
#     union all
#     select
#       c.arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       'ec2 classic lb' as title,
#       'ec2_classic_load_balancer_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', c.arn,
#         'Account ID', c.account_id,
#         'Region', c.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_ec2_classic_load_balancer as c on c.vpc_id = v.vpc_id

#     -- From EC2 Gateway LBs (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_ec2_gateway_load_balancer' as category,
#       jsonb_build_object(
#         'ARN', arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       aws_ec2_gateway_load_balancer as g
#     where
#       g.vpc_id  = $1

#     -- From EC2 Gateway LBs (edge)
#     union all
#     select
#       g.arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       'ec2 gateway lb' as title,
#       'ec2_gateway_load_balancer_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', g.arn,
#         'Account ID', g.account_id,
#         'Region', g.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_ec2_gateway_load_balancer as g on g.vpc_id = v.vpc_id

#     -- From RDS DB Instances (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_rds_db_instance' as category,
#       jsonb_build_object(
#         'ARN', arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       aws_rds_db_instance as i
#     where
#       i.vpc_id  = $1

#     -- From RDS DB Instances (edge)
#     union all
#     select
#       i.arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       'rds db instance' as title,
#       'rds_db_instance_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', i.arn,
#         'Account ID', i.account_id,
#         'Region', i.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_rds_db_instance as i on i.vpc_id = v.vpc_id

#     -- From Redshift Clusters (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_redshift_cluster' as category,
#       jsonb_build_object(
#         'ARN', arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       aws_redshift_cluster as c
#     where
#       c.vpc_id  = $1

#     -- From Redshift Clusters (edge)
#     union all
#     select
#       c.arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       'redshift cluster' as title,
#       'redshift_cluster_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', c.arn,
#         'Account ID', c.account_id,
#         'Region', c.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_redshift_cluster as c on c.vpc_id = v.vpc_id

#     -- From EC2 Target Groups (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       target_group_arn as id,
#       title as title,
#       'aws_ec2_target_group' as category,
#       jsonb_build_object(
#         'ARN', target_group_arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       aws_ec2_target_group as t
#     where
#       t.vpc_id  = $1

#     -- From EC2 Target Groups (edge)
#     union all
#     select
#       t.target_group_arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       'target group' as title,
#       'ec2_target_group_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', t.target_group_arn,
#         'Account ID', t.account_id,
#         'Region', t.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_ec2_target_group as t on t.vpc_id = v.vpc_id

#     -- From FSX File Systems (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       arn as id,
#       title as title,
#       'aws_fsx_file_system' as category,
#       jsonb_build_object(
#         'ARN', arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       aws_fsx_file_system as f
#     where
#       f.vpc_id  = $1

#     -- From FSX File Systems (edge)
#     union all
#     select
#       f.arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       'fsx file system' as title,
#       'fsx_file_system_to_vpc' as category,
#       jsonb_build_object(
#         'ARN', f.arn,
#         'Account ID', f.account_id,
#         'Region', f.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_fsx_file_system as f on f.vpc_id = v.vpc_id

#     -- From S3 Access Points (node)
#     union all
#     select
#       null as from_id,
#       null as to_id,
#       access_point_arn as id,
#       title as title,
#       'aws_vpc_endpoint' as category,
#       jsonb_build_object(
#         'ARN', access_point_arn,
#         'Account ID', account_id,
#         'Region', region
#       ) as properties
#     from
#       aws_s3_access_point as a
#     where
#       a.vpc_id  = $1

#     -- From S3 Access Points (edge)
#     union all
#     select
#       a.access_point_arn as from_id,
#       v.vpc_id as to_id,
#       null as id,
#       's3 access point' as title,
#       'uses' as category,
#       jsonb_build_object(
#         'ARN', a.access_point_arn,
#         'Account ID', a.account_id,
#         'Region', a.region
#       ) as properties
#     from
#       vpc as v
#       left join aws_s3_access_point as a on a.vpc_id = v.vpc_id

#   EOQ
#   param "vpc_id" {}

# }



#### New Node/Edge format Graph queries ############

node "aws_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      vpc_id as id,
      title as title,
      jsonb_build_object(
        'VPC ID', vpc_id,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}


node "aws_vpc_az_node" {
  category = category.aws_availability_zone

  sql = <<-EOQ
    select
      distinct on (availability_zone)
      availability_zone as id,
      availability_zone as title,
      jsonb_build_object(
        'Availability Zone', availability_zone,
        'Availability Zone ID', availability_zone_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_subnet
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_az_edge" {
  title = "az"

  sql = <<-EOQ
    select
      distinct on (availability_zone)
      $1 as from_id,
      availability_zone as to_id
    from
      aws_vpc_subnet
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}


node "aws_vpc_vpc_subnet_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      subnet_id as id,
      title as title,
      jsonb_build_object(
        'ARN', subnet_arn,
        'Subnet ID', subnet_id,
        'CIDR Block', cidr_block,
        'IP Address Count', available_ip_address_count,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_subnet
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}


edge "aws_vpc_az_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      availability_zone as from_id,
      subnet_id as to_id
    from
      aws_vpc_subnet
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}

node "aws_vpc_igw_node" {
  category = category.aws_vpc_internet_gateway

  sql = <<-EOQ
    select
      internet_gateway_id as id,
      title as title,
      jsonb_build_object(
        'ID', internet_gateway_id,
        'State', a ->> 'State',
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_internet_gateway,
      jsonb_array_elements(attachments) as a
    where
      a ->> 'VpcId' = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_igw_edge" {
  title = "internet gateway"

  sql = <<-EOQ
    select
      a ->> 'VpcId' as to_id,
      i.internet_gateway_id as from_id
    from
      aws_vpc_internet_gateway as i,
      jsonb_array_elements(attachments) as a
    where
      a ->> 'VpcId' = $1
  EOQ

  param "vpc_id" {}
}

node "aws_vpc_az_route_table" {
  category = category.aws_vpc_route_table

  sql = <<-EOQ
    select
      route_table_id as id,
      case 
        when associations @> '[{"Main": true}]' 
          then concat(title,' [Default]')
        else
          title
        end as title,
      jsonb_build_object(
        'ID', route_table_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_route_table
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_subnet_route_table_edge" {
  title = "route table"

  sql = <<-EOQ
    select
       a ->> 'SubnetId' as to_id,
      rt.route_table_id as from_id
      from
        aws_vpc_route_table as rt,
        jsonb_array_elements(associations) as a
      where
        rt.vpc_id = $1
  EOQ

  param "vpc_id" {}
}


edge "aws_vpc_vpc_route_table_edge" {
  title = "route table"

  sql = <<-EOQ
    select
      rt.vpc_id as from_id,
      rt.route_table_id as to_id
      from
        aws_vpc_route_table as rt,
        jsonb_array_elements(associations) as a
      where
        rt.vpc_id = $1
  EOQ

  param "vpc_id" {}
}


node "aws_vpc_vcp_endpoint_node" {
  category = category.aws_vpc_endpoint

  sql = <<-EOQ
    select
      vpc_endpoint_id as id,
      title as title,
      jsonb_build_object(
        'ID', vpc_endpoint_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_endpoint
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}


edge "aws_vpc_subnet_endpoint_edge" {
  title = "vpc endpoint"

  sql = <<-EOQ
    select
      coalesce(s, e.vpc_id) as from_id,
      e.vpc_endpoint_id as to_id
    from
      aws_vpc_endpoint as e,
      jsonb_array_elements_text(e.subnet_ids) as s
    where
      e.vpc_id = $1
  EOQ

  param "vpc_id" {}
}

node "aws_vpc_transit_gateway_node" {
  category = category.aws_ec2_transit_gateway

  sql = <<-EOQ
    select
      g.transit_gateway_id as id,
      g.title as title,
      jsonb_build_object(
        'ID', g.transit_gateway_id,
        'ARN', g.transit_gateway_arn,
        'Attachment Id', t.transit_gateway_attachment_id,
        'Association State', t.association_state,
        'Region', g.region,
        'Account ID', g.account_id
      ) as properties
    from
      aws_ec2_transit_gateway_vpc_attachment as t
      left join aws_ec2_transit_gateway as g on t.transit_gateway_id = g.transit_gateway_id
    where
      t.resource_id = $1 and resource_type = 'vpc'
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_transit_gateway_edge" {
  title = "transit_gateway"

  sql = <<-EOQ
    select
      resource_id as to_id,
      transit_gateway_id as from_id
    from
      aws_ec2_transit_gateway_vpc_attachment
      where resource_id = $1
  EOQ

  param "vpc_id" {}
}

node "aws_vpc_nat_gateway_node" {
  category = category.aws_vpc_nat_gateway

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'ID', nat_gateway_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_nat_gateway
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_subnet_nat_gateway_edge" {
  title = "nat gateway"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      arn as to_id
    from
      aws_vpc_nat_gateway 
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}

node "aws_vpc_vpn_gateway_node" {
  category = category.aws_vpc_vpn_gateway

  sql = <<-EOQ
    select
      vpn_gateway_id as id,
      title as title,
      jsonb_build_object(
        'ID', vpn_gateway_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_vpn_gateway,
      jsonb_array_elements(vpc_attachments) as a
    where
      a ->> 'VpcId' = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_vpn_gateway_edge" {
  title = "vpn gateway"

  sql = <<-EOQ
    select
      a ->> 'VpcId' as to_id,
      g.vpn_gateway_id as from_id
    from
      aws_vpc_vpn_gateway as g,
      jsonb_array_elements(vpc_attachments) as a
    where
      a ->> 'VpcId' = $1
  EOQ

  param "vpc_id" {}
}

node "aws_vpc_vpc_security_group_node" {
  category = category.aws_vpc_security_group

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Group ID', group_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_security_group
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      vpc_id as from_id,
      arn as to_id
    from
      aws_vpc_security_group
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}



node "aws_vpc_peered_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    -- with vpcs as (
      select
        accepter_vpc_id as id,
        vpc.title as title,
        jsonb_build_object(
          'VPC ID', accepter_vpc_id,
          'CIDR', accepter_cidr_block,
          'Status', status_code,
          'Region', accepter_region,
          'Account ID', accepter_owner_id
        ) as properties
      from
        aws_vpc_peering_connection,
        aws_vpc as vpc
      where
        accepter_vpc_id = vpc.vpc_id
        and requester_vpc_id = $1
        
      union all select
        requester_vpc_id as id,
        vpc.title as title,
        jsonb_build_object(
          'VPC ID', requester_vpc_id,
          'CIDR', requester_cidr_block,
          'Status', status_code,
          'Region', requester_region,
          'Account ID', requester_owner_id
        ) as properties
      from
        aws_vpc_peering_connection,
        aws_vpc as vpc
      where
        requester_vpc_id = vpc.vpc_id
        and accepter_vpc_id = $1
        

  EOQ

  param "vpc_id" {}
}




edge "aws_vpc_peered_vpc_edge" {
  title = "peered with"

  sql = <<-EOQ
    select
      $1 as to_id,
      case 
        when accepter_vpc_id = $1 then requester_vpc_id
        else accepter_vpc_id
      end as from_id
    from
      aws_vpc_peering_connection
    where 
      accepter_vpc_id = $1
      or requester_vpc_id = $1
  EOQ

  param "vpc_id" {}
}



node "aws_vpc_ec2_instance_node" {
  category = category.aws_ec2_instance

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_instance
    where
      vpc_id  = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_subnet_instance_edge" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      arn as to_id
    from
      aws_ec2_instance 
    where 
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}


node "aws_vpc_lambda_function_node" {
  category = category.aws_lambda_function

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_lambda_function
    where
      vpc_id  = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_subnet_lambda_edge" {
  title = "lambda function"

  sql = <<-EOQ
    select
      s as from_id,
      l.arn as to_id
    from
      aws_lambda_function as l,
      jsonb_array_elements_text(l.vpc_subnet_ids) as s
    where 
      l.vpc_id = $1
  EOQ

  param "vpc_id" {}
}

node "aws_vpc_alb_node" {
  category = category.aws_ec2_application_load_balancer

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_application_load_balancer
    where
      vpc_id  = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_subnet_alb_edge" {
  title = "alb"

  sql = <<-EOQ
    select
      az ->> 'SubnetId' as from_id,
      a.arn as to_id
    from
      aws_ec2_application_load_balancer as a, 
      jsonb_array_elements(availability_zones) as az
    where
      a.vpc_id = $1
  EOQ

  param "vpc_id" {}
}

node "aws_vpc_nlb_node" {
  category = category.aws_ec2_network_load_balancer

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_network_load_balancer
    where
      vpc_id  = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_subnet_nlb_edge" {
  title = "nlb"

  sql = <<-EOQ
    select
      az ->> 'SubnetId' as from_id,
      n.arn as to_id
    from
      aws_ec2_network_load_balancer as n,
      jsonb_array_elements(availability_zones) as az
    where n.vpc_id = $1
  EOQ

  param "vpc_id" {}
}


node "aws_vpc_security_elb_node" {
  category = category.aws_ec2_classic_load_balancer

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_classic_load_balancer
    where
      vpc_id  = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_subnet_elb_edge" {
  title = "elb"

  sql = <<-EOQ
    select
      s as from_id,
      c.arn as to_id
    from
      aws_ec2_classic_load_balancer as c,
      jsonb_array_elements_text(subnets) as s
    where 
      c.vpc_id = $1
  EOQ

  param "vpc_id" {}
}


node "aws_vpc_gwlbnode" {
  category = category.aws_ec2_gateway_load_balancer

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_gateway_load_balancer
    where
      vpc_id  = $1
  EOQ

  param "vpc_id" {}
}

edge "aws_vpc_subnet_gwlb_edge" {
  title = "gwlb"

  sql = <<-EOQ
    select
      az ->> 'SubnetId' as from_id,
      g.arn as to_id
    from
      aws_ec2_gateway_load_balancer as g,
      jsonb_array_elements(availability_zones) as az
    where
      g.vpc_id = $1
  EOQ

  param "vpc_id" {}
}


node "aws_vpc_rds_instance_node" {
  category = category.aws_rds_db_instance

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_instance
    where
      vpc_id  = $1
  EOQ

  param "vpc_id" {}
}


edge "aws_vpc_subnet_rds_edge" {
  title = "rds instance"

  sql = <<-EOQ
    select
      s ->> 'SubnetIdentifier' as from_id,
      i.arn as to_id
    from
      aws_rds_db_instance as i,
      jsonb_array_elements(subnets) as s
    where
      i.vpc_id = $1
  EOQ

  param "vpc_id" {}
}


node "aws_vpc_redshift_cluster_node" {
  category = category.aws_redshift_cluster

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_redshift_cluster
    where
      vpc_id  = $1
  EOQ

  param "vpc_id" {}
}



   # -- Subnet -> Redshift Clusters (edge)
   # -- TO DO: These should connect to subnets, not vpcs (dont have any to test with right now...)
edge "aws_vpc_subnet_redshift_edge" {
  title = "redshift cluster"

  sql = <<-EOQ
    select
      arn as from_id,
      vpc_id as to_id
    from
      aws_redshift_cluster 
    where
     vpc_id = $1
  EOQ

  param "vpc_id" {}
}

node "aws_vpc_fsx_filesystem_node" {
  category = category.aws_fsx_file_system

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_fsx_file_system
    where
      vpc_id  = $1
  EOQ

  param "vpc_id" {}
}


   # -- Subnet -> FSX File Systems (edge)
   # -- TO DO: These should connect to subnets, not vpcs (dont have any to test with right now...)
edge "aws_vpc_subnet_fxs_edge" {
  title = "fsx file system"

  sql = <<-EOQ
    select
      arn as from_id,
      vpc_id as to_id
    from
      aws_fsx_file_system
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}


node "aws_vpc_s3_access_point_node" {
  category = category.aws_s3_access_point

  sql = <<-EOQ
    select
      access_point_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', access_point_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_s3_access_point
    where
      vpc_id  = $1
  EOQ

  param "vpc_id" {}
}


edge "aws_vpc_s3_access_point_edge" {
  title = "s3 access point"

  sql = <<-EOQ
    select
      vpc_id as from_id,
      access_point_arn as to_id
    from
      aws_s3_access_point
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}

###############################################################


#### New Node/Edge format Flow queries ############


node "aws_vpc_routing_subnet_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      a ->> 'SubnetId' as id,
      a ->> 'SubnetId' as title,
      0 as depth
    from
      aws_vpc_route_table,
      jsonb_array_elements(routes) as r,
      jsonb_array_elements(associations) as a
    where
      vpc_id = $1
      and a ->> 'SubnetId' is not null
  EOQ

  param "vpc_id" {}
}

node "aws_vpc_routing_vpc_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      vpc_id as id,
      vpc_id as title,
      0 as depth
    from
      aws_vpc_route_table,
      jsonb_array_elements(routes) as r,
      jsonb_array_elements(associations) as a
    where
      vpc_id = $1
      and a ->> 'SubnetId' is null

  EOQ

  param "vpc_id" {}
}

node "aws_vpc_routing_cidr_node" {
  //category = category.cidr_block

  sql = <<-EOQ
    select
      coalesce(r ->> 'DestinationCidrBlock' , r ->> 'DestinationIpv6CidrBlock') as id,
      coalesce(r ->> 'DestinationCidrBlock' , r ->> 'DestinationIpv6CidrBlock') as title,
      'cider_block' as category,
      1 as depth
    from
      aws_vpc_route_table,
      jsonb_array_elements(routes) as r,
      jsonb_array_elements(associations) as a
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}



edge "aws_vpc_routing_subnet_vpc_to_cidr_edge" {
  title = "cidr"

  sql = <<-EOQ
    select
      coalesce(a ->> 'SubnetId', vpc_id) as from_id,
      coalesce(r ->> 'DestinationCidrBlock' , r ->> 'DestinationIpv6CidrBlock') as to_id
    from
      aws_vpc_route_table,
      jsonb_array_elements(routes) as r,
      jsonb_array_elements(associations) as a
    where
      vpc_id = $1
  EOQ

  param "vpc_id" {}
}



node "aws_vpc_routing_gateway_node" {
  category = category.aws_vpc_internet_gateway

  sql = <<-EOQ
      select
        coalesce(
          r ->> 'GatewayId',
          r ->> 'InstanceId',
          r ->> 'NatGatewayId',
          r ->> 'LocalGatewayId',
          r ->> 'CarrierGatewayId',
          r ->> 'TransitGatewayId',
          r ->> 'VpcPeeringConnectionId',
          r ->> 'DestinationPrefixListId',
          r ->> 'DestinationIpv6CidrBlock',
          r ->> 'EgressOnlyInternetGatewayId',
          r ->> 'NetworkInterfaceId',
          r ->> 'CoreNetworkArn',
          r ->> 'InstanceOwnerId'
        ) as id,
        coalesce(
          r ->> 'GatewayId',
          r ->> 'InstanceId',
          r ->> 'NatGatewayId',
          r ->> 'LocalGatewayId',
          r ->> 'CarrierGatewayId',
          r ->> 'TransitGatewayId',
          r ->> 'VpcPeeringConnectionId',
          r ->> 'DestinationPrefixListId',
          r ->> 'DestinationIpv6CidrBlock',
          r ->> 'EgressOnlyInternetGatewayId',
          r ->> 'NetworkInterfaceId',
          r ->> 'CoreNetworkArn',
          r ->> 'InstanceOwnerId'
        ) title
      from
        aws_vpc_route_table,
        jsonb_array_elements(routes) as r
      where
        vpc_id = $1
  EOQ

  param "vpc_id" {}
}



edge "aws_vpc_routing_cidr_to_gateway_edge" {

  title = "gateway"
  sql = <<-EOQ
      select
        coalesce(
            r ->> 'DestinationCidrBlock', 
            r ->> 'DestinationIpv6CidrBlock'
        ) as from_id,
        coalesce(
          r ->> 'GatewayId',
          r ->> 'InstanceId',
          r ->> 'NatGatewayId',
          r ->> 'LocalGatewayId',
          r ->> 'CarrierGatewayId',
          r ->> 'TransitGatewayId',
          r ->> 'VpcPeeringConnectionId',
          r ->> 'DestinationPrefixListId',
          r ->> 'DestinationIpv6CidrBlock',
          r ->> 'EgressOnlyInternetGatewayId',
          r ->> 'NetworkInterfaceId',
          r ->> 'CoreNetworkArn',
          r ->> 'InstanceOwnerId'
        ) as to_id
      from
        aws_vpc_route_table,
        jsonb_array_elements(routes) as r
        --jsonb_array_elements(associations) as a
      where
        vpc_id = $1
  EOQ

  param "vpc_id" {}
}
