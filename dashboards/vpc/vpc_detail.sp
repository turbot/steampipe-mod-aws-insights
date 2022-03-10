dashboard "aws_vpc_detail" {

  title = "AWS VPC Detail"
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
      args  = {
        vpc_id = self.input.vpc_id.value
      }
    }

    card {
      width = 2
      query = query.aws_subnet_count_for_vpc
      args  = {
        vpc_id = self.input.vpc_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_is_default
      args  = {
        vpc_id = self.input.vpc_id.value
      }
    }

    card {
      width = 2
      query = query.aws_flow_logs_count_for_vpc
      args  = {
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
        args  = {
          vpc_id = self.input.vpc_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_vpc_tags
        args  = {
          vpc_id = self.input.vpc_id.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "CIDR Blocks"
        query = query.aws_vpc_cidr_blocks
        args  = {
          vpc_id = self.input.vpc_id.value
        }
      }

      table {
        title = "DHCP Options"
        query = query.aws_vpc_dhcp_options
        args  = {
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
      query = query.aws_vpc_routes_for_vpc_sankey
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

    flow {
      title = "Peering Connections"
      width = 6
      query = query.aws_vpc_peers_for_vpc_sankey
      args = {
        vpc_id = self.input.vpc_id.value
      }

      category "failed" {
        color = "alert"
      }

      category "active" {
        color = "ok"
      }
    }

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
      base = flow.nacl_flow
      title = "Ingress NACLs"
      width = 6
      query = query.aws_ingress_nacl_for_vpc_sankey
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }


    flow {
      base = flow.nacl_flow
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

query "aws_vpc_routes_for_vpc_sankey" {
  sql = <<-EOQ
    with routes as (
    select
        route_table_id,
        vpc_id,
        r ->> 'State' as state,
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
        end as gateway,
        case
          when r ->> 'DestinationCidrBlock' is not null then r ->> 'DestinationCidrBlock'
          when r ->> 'DestinationIpv6CidrBlock' is not null then r ->> 'DestinationIpv6CidrBlock'
          else '???'
        end as destination_cidr,
        case
          when a ->> 'Main' = 'true' then vpc_id
          when a ->> 'SubnetId' is not null then  a->> 'SubnetId'
          else '??'
        end as associated_to

      from
        aws_vpc_route_table,
        jsonb_array_elements(routes) as r,
        jsonb_array_elements(associations) as a
      where
        vpc_id = $1
    )
      select
        null as from_id,
        associated_to as id,
        associated_to as title,
        'aws_vpc_route_table' as category,
        0 as depth
      from
        routes
      union
        select
          associated_to as from_id,
          destination_cidr as id,
          destination_cidr as title,
          'vpc_or_subnet' as category,
          1 as depth
        from
          routes
      union
        select
          destination_cidr as from_id,
          gateway as id,
          gateway as title,
          'gateway' as category,
          2 as depth
        from
          routes
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
    
    -- nacl -> subnet edge
    union select 
      null as id,
      null as title,
      'attached' as category,
      network_acl_id as from_id,
      subnet_id as to_id, 
      null as depth
    from aces

    -- rule -> NACL edge
    union select 
      null as id,
      null as title,
      rule_action as category,
      concat(network_acl_id, '_', rule_num_padded) as from_id,
      network_acl_id as to_id,
      null as depth
    from aces

    -- ip -> rule edge
    union select 
      null as id,
      null as title,
      rule_action as category,
      cidr_block as from_id,
      concat(network_acl_id, '_', rule_num_padded) as to_id,
      null as depth
    from aces

  EOQ

  param "vpc_id" {}
}
query "aws_vpc_peers_for_vpc_sankey" {
  sql = <<-EOQ
    with peers as (
      select
        id,
        status_code,
        requester_owner_id,
        requester_region,
        requester_vpc_id,
        coalesce(requester_cidr_block::text, 'null') as requester_cidr_block,
        accepter_owner_id,
        accepter_region,
        accepter_vpc_id,
        coalesce(accepter_cidr_block::text, 'null') as accepter_cidr_block
      from
        aws_vpc_peering_connection
      where
        requester_vpc_id = $1
        or accepter_vpc_id = $1
    )
    select
      concat('requestor_', requester_owner_id) as from_id,
      concat('requestor_', requester_cidr_block) as id,
      requester_cidr_block::text as title,
      0 as depth,
      status_code as category
    from
      peers
    union select
      concat('requestor_', requester_region) as from_id,
      concat('requestor_', requester_owner_id) as id,
      requester_owner_id as title,
      1 as depth,
      'account' as category
    from
      peers
    union select
      id as from_id,
      concat('requestor_', requester_region) as id,
      requester_region as title,
      2 as depth,
      'region' as category
    from
      peers
    union select
      null as from_id,
      id,
      id as title,
      3 as depth,
      status_code as category
    from
      peers
    union select
      id as from_id,
      concat('acceptor_', accepter_region) as id,
      accepter_region as title,
      4 as depth,
      'region' as category
    from
      peers
    union select
      concat('acceptor_', accepter_region) as from_id,
      concat('acceptor_', accepter_owner_id) as id,
      accepter_owner_id as title,
      5 as depth,
      'account' as category
    from
      peers
    union  select
      concat('acceptor_', accepter_owner_id) as from_id,
      concat('acceptor_', accepter_cidr_block) as id,
      accepter_cidr_block::text as title,
      6 as depth,
      status_code as category
    from
      peers
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
  sql   = <<-EOQ
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
