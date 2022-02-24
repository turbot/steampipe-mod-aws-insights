
query "aws_subnet_count_for_vpc" {
  sql = <<-EOQ
    select
      'Subnets' as label,
      count(*) as value,
      case when count(*) > 0 then 'ok' else 'alert' end as type
    from
      aws_vpc_subnet
    where
      vpc_id = 'vpc-9d7ae1e7'
  EOQ
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
      vpc_id = 'vpc-9d7ae1e7'
  EOQ
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
      where vpc_id = 'vpc-9d7ae1e7'

    )
    select
      sum(num_ips) as "IP Addresses"
    from
      cidrs

  EOQ
}


query "aws_flowlogs_count_for_vpc" {
  sql = <<-EOQ
    select
      'Flow Logs' as label,
      count(*) as value,
      case when count(*) > 0 then 'ok' else 'alert' end as type
    from
      aws_vpc_flow_log
    where resource_id = 'vpc-9d7ae1e7'
  EOQ
}




query "aws_vpc_subnets_for_vpc" {
  sql = <<-EOQ
    with subnets as (
      select
        title,
        subnet_id ,
        cidr_block,
        availability_zone,
        available_ip_address_count,
        power(2, 32 - masklen(cidr_block :: cidr)) -1 as raw_size
      from
        aws_vpc_subnet
      where
        vpc_id = 'vpc-9d7ae1e7'
    )
    select
      title as "Title",
      subnet_id as "Subnet ID",
      cidr_block as "CIDR Block",
      availability_zone as "Availbility Zone",
      available_ip_address_count as "Available IPs",
      power(2, 32 - masklen(cidr_block :: cidr)) -1 as "Total IPs",
      round(100 * (available_ip_address_count / (raw_size))::numeric, 2) as "% Free"
    from
      subnets
  EOQ
}


query "aws_vpc_security_groups_for_vpc" {
  sql = <<-EOQ
    select
      group_name,
      group_id,
      description
    from
      aws_vpc_security_group
    where
      vpc_id = 'vpc-9d7ae1e7'
  EOQ
}



query "aws_vpc_endpoints_for_vpc" {
  sql = <<-EOQ
    select
      vpc_endpoint_id,
      title,
      service_name
    from
      aws_vpc_endpoint
    where
      vpc_id = 'vpc-9d7ae1e7'
  EOQ
}





query "aws_vpc_route_tables_for_vpc" {
  sql = <<-EOQ
    select
      title,
      route_table_id
      -- jsonb_pretty(associations),
      -- jsonb_pretty(routes)
    from
      aws_vpc_route_table
    where
      vpc_id = 'vpc-9d7ae1e7'
  EOQ
}






query "aws_vpc_routes_for_vpc_sankey" {
  sql = <<-EOQ

  with routes as (
   select
      route_table_id,
      vpc_id,
      -- jsonb_pretty(a),
      -- jsonb_pretty(routes),
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
      vpc_id = 'vpc-9d7ae1e7' --'vpc-078f28832846343e5' --
)
    select
      null as parent,
      associated_to as id,
      associated_to as name,
      'aws_vpc_route_table' as category,
      0 as depth
    from
      routes
    union
      select
        associated_to as parent,
        destination_cidr as id,
        destination_cidr as name,
        'vpc_or_subnet' as category,
        1 as depth
      from
        routes
    union
      select
        destination_cidr as parent,
        gateway as id,
        gateway as name,
        'gateway' as category,
        2 as depth
      from
        routes



  EOQ
}




query "aws_vpc_routes_for_vpc" {
  sql = <<-EOQ
    select
      route_table_id,
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
      r ->> 'DestinationCidrBlock' as destination_cidr,
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
      vpc_id = 'vpc-9d7ae1e7'

    order by
      route_table_id,
      associated_to,
      destination_cidr,
      gateway


  EOQ
}




query "aws_vpc_peers_for_vpc" {
  sql = <<-EOQ
    select
      -- distinct id, -- seems to be broken (EOF)
      id,
      status_code,
      requester_owner_id,
      requester_region,
      requester_vpc_id,
      requester_cidr_block,
      accepter_owner_id,
      accepter_region,
      accepter_vpc_id,
      accepter_cidr_block
    from
      aws_vpc_peering_connection
    where
      requester_vpc_id = 'vpc-9d7ae1e7'
      or accepter_vpc_id = 'vpc-9d7ae1e7'
  EOQ
}


query "aws_vpc_gateways_for_vpc" {
  sql = <<-EOQ
    select
      title,
      internet_gateway_id as id,
      'aws_vpc_internet_gateway' as type,
      a ->> 'State' as state
      -- ip_address
    from
      aws_vpc_internet_gateway,
      jsonb_array_elements(attachments) as a
     where
      a ->> 'VpcId' = 'vpc-9d7ae1e7'


    union all select
      title,
      id,
      'aws_vpc_egress_only_internet_gateway' as type,
      a ->> 'State' as state
      -- ip_address
    from
      aws_vpc_egress_only_internet_gateway,
      jsonb_array_elements(attachments) as a
     where
      a ->> 'VpcId' = 'vpc-9d7ae1e7'


    union all select
      title,
      vpn_gateway_id as id,
      'aws_vpc_vpn_gateway' as type,
      a ->> 'State' as state
      -- ip_address
    from
      aws_vpc_vpn_gateway,
      jsonb_array_elements(vpc_attachments) as a
     where
      a ->> 'VpcId' = 'vpc-9d7ae1e7'

    union all select
      title,
      nat_gateway_id as id,
      'aws_vpc_nat_gateway' as type,
      state
      -- ip_address
    from
      aws_vpc_nat_gateway
     where
       vpc_id = 'vpc-9d7ae1e7'

  EOQ
}


query "aws_ingress_nacl_for_vpc_sankey" {
  sql   = <<-EOQ
    with nacl_data as (
      select
        title,
        network_acl_id,
        is_default,
        entries,
        associations
      from
        aws_vpc_network_acl
      where
        vpc_id = 'vpc-9d7ae1e7'
    )

    -- CIDRS
    select
      concat(network_acl_id, '_'::text, e ->> 'RuleNumber', '_port_proto') as parent,
      e ->> 'CidrBlock' as id,
      e ->> 'CidrBlock' as name,
      0 as depth,
      e ->> 'RuleAction' as category
    from
      nacl_data,
      jsonb_array_elements(entries) as e
    where
      not (e ->> 'Egress')::boolean


    -- Port - protcol
    union all select
      concat(network_acl_id, '_', to_char((e->>'RuleNumber')::numeric, 'fm00000'))  as parent,
      concat(network_acl_id, '_'::text, e ->> 'RuleNumber', '_port_proto') as id,

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
      end as name,
      1 as depth,
      e ->> 'RuleAction' as category
    from
      nacl_data,
      jsonb_array_elements(entries) as e
    where
      not (e ->> 'Egress')::boolean


   union all select
      network_acl_id as parent,
      concat(network_acl_id, '_', to_char( (e->>'RuleNumber')::numeric, 'fm00000')) as id,
      concat('Rule #', e ->> 'RuleNumber')  as name,
      2 as depth,
      e ->> 'RuleAction' as category
    from
      nacl_data,
      jsonb_array_elements(entries) as e
    where
      not (e ->> 'Egress')::boolean
    -- order by
    --   e -> 'RuleNumber'

    union all select
      null as parent,
      network_acl_id as id,
      network_acl_id as name,
      3 as depth,
      'aws_vpc_network_acl' as category
    from
      nacl_data

    union all select
      a->>'NetworkAclId' as parent,
      a->>'SubnetId' as id,
      a->>'SubnetId' as name,
      4 as depth,
      'aws_vpc_subnet' as category
    from
      nacl_data,
      jsonb_array_elements(associations) as a
  EOQ
}







query "aws_egress_nacl_for_vpc_sankey" {
  sql   = <<-EOQ
    with nacl_data as (
      select
        title,
        network_acl_id,
        is_default,
        entries,
        associations
      from
        aws_vpc_network_acl
      where
        vpc_id = 'vpc-9d7ae1e7'
    )

    select
      a->>'NetworkAclId' as parent,
      a->>'SubnetId' as id,
      a->>'SubnetId' as name,
      0 as depth,
      'aws_vpc_subnet' as category
    from
      nacl_data,
      jsonb_array_elements(associations) as a

    union all select
      null as parent,
      network_acl_id as id,
      network_acl_id as name,
      1 as depth,
      'aws_vpc_network_acl' as category
    from
      nacl_data

   union all select
      network_acl_id as parent,
      concat(network_acl_id, '_', to_char( (e->>'RuleNumber')::numeric, 'fm00000')) as id,
      concat('Rule #', e ->> 'RuleNumber')  as name,
      2 as depth,
      e ->> 'RuleAction' as category
    from
      nacl_data,
      jsonb_array_elements(entries) as e
    where
      (e ->> 'Egress')::boolean

-- Port - protcol
    union all select
      concat(network_acl_id, '_', to_char((e->>'RuleNumber')::numeric, 'fm00000'))  as parent,
      concat(network_acl_id, '_'::text, e ->> 'RuleNumber', '_port_proto') as id,


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
      end as name,
      3 as depth,
      e ->> 'RuleAction' as category
    from
      nacl_data,
      jsonb_array_elements(entries) as e
    where
      (e ->> 'Egress')::boolean

    -- CIDRS
    union all select
      concat(network_acl_id, '_'::text, e ->> 'RuleNumber', '_port_proto') as parent,
      e ->> 'CidrBlock' as id,
      e ->> 'CidrBlock' as name,
      4 as depth,
      e ->> 'RuleAction' as category
    from
      nacl_data,
      jsonb_array_elements(entries) as e
    where
      (e ->> 'Egress')::boolean

  EOQ
}




query "aws_vpc_peers_for_vpc_sankey" {
  sql   = <<-EOQ
    with peers as (
      select
        -- distinct id, -- seems to be broken (EOF)
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
        requester_vpc_id = 'vpc-9d7ae1e7'
        or accepter_vpc_id = 'vpc-9d7ae1e7'
    )
    select
      -- null as parent,
      concat('requestor_', requester_owner_id) as parent,
      concat('requestor_', requester_cidr_block) as id,
      requester_cidr_block::text as name,
      0 as depth,
      status_code as category
    from
      peers

    union select
      concat('requestor_', requester_region) as parent,
      --null as parent,
      concat('requestor_', requester_owner_id) as id,
      requester_owner_id as name,
      1 as depth,
      'account' as category
    from
      peers

    union select
      -- concat('requestor_', requester_cidr_block) as parent,
      id as parent,
      concat('requestor_', requester_region) as id,
      requester_region as name,
      2 as depth,
      'region' as category
    from
      peers



    union select
      --concat('requestor_', requester_owner_id)  as parent,
      null as parent,
      id,
      id as name,
      3 as depth,
      status_code as category
    from
      peers

    union select
      -- concat('acceptor_', accepter_owner_id) as parent,
      id as parent,
      concat('acceptor_', accepter_region) as id,
      accepter_region as name,
      4 as depth,
      'region' as category
    from
      peers

    union select
      -- id as parent,
      concat('acceptor_', accepter_region) as parent,
      concat('acceptor_', accepter_owner_id) as id,
      accepter_owner_id as name,
      5 as depth,
      'account' as category
    from
      peers


    union  select
      concat('acceptor_', accepter_owner_id) as parent,
      concat('acceptor_', accepter_cidr_block) as id,
      accepter_cidr_block::text as name,
      6 as depth,
      status_code as category
    from
      peers

  EOQ
}




dashboard aws_vpc_detail {
  title = "AWS VPC  Detail"

  input "vpc_id" {
    title = "VPC"
    sql   = <<-EOQ
      select
        vpc_id
      from
        aws_vpc
    EOQ
    width = 2
  }

  container {


     # Analysis
    card {
      #title = "Size"
      sql   = query.aws_vpc_num_ips_for_vpc.sql
      width = 2
    }

    #    # Assessments
    card {
      #title = "Subnet Count"
      sql   = query.aws_subnet_count_for_vpc.sql
      width = 2
    }

    card {
      sql   = query.aws_vpc_is_default.sql
      width = 2
    }

    card {
      sql = query.aws_flowlogs_count_for_vpc.sql
      width = 2
    }

  }



  container {
    # title = "Overiew"

    container {

      table {
        title = "Overview"
        type = "list"
        width = 6
        sql   = <<-EOQ
          select
            title,
            vpc_id,
            region,
            account_id,
            arn
          from
            aws_vpc
          where
            vpc_id = 'vpc-9d7ae1e7'
        EOQ
      }



      table {
        title = "Tags"
        width = 6

        sql   = <<-EOQ
          select
            tag ->> 'Key' as "Key",
            tag ->> 'Value' as "Value"
          from
            aws_vpc,
            jsonb_array_elements(tags_src) as tag
          where
            vpc_id = 'vpc-9d7ae1e7'
        EOQ
      }


      table {
        title = "CIDR Blocks"
        width = 6

        sql   = <<-EOQ
          select
            b ->> 'CidrBlock' as cidr_block,
            power(2, 32 - masklen( (b ->> 'CidrBlock'):: cidr)) as num_ips
          from
            aws_vpc,
            jsonb_array_elements(cidr_block_association_set) as b
          where vpc_id = 'vpc-9d7ae1e7'

          union all select
            b ->> 'Ipv6CidrBlock' as cidr_block,
            power(2, 128 - masklen( (b ->> 'Ipv6CidrBlock'):: cidr)) as num_ips
          from
            aws_vpc,
            jsonb_array_elements(ipv6_cidr_block_association_set) as b
          where vpc_id = 'vpc-9d7ae1e7'
        EOQ
      }



      table {
        title = "DHCP Options"
        width = 6

        sql   = <<-EOQ
          select
            d.title,
            d.dhcp_options_id,
            d.domain_name,
            d.domain_name_servers,
            d.netbios_name_servers,
            d.netbios_node_type,
            d.ntp_servers
          from
            aws_vpc as v,
            aws_vpc_dhcp_options as d
          where
            vpc_id = 'vpc-9d7ae1e7'
            and v.dhcp_options_id = d.dhcp_options_id
        EOQ
      }

    }

  }

  container {
    title = "Subnets"


    chart {
      title = "Subnets by AZ"
      sql   = <<-EOQ
        select
          availability_zone,
          count(*)
        from
          aws_vpc_subnet
        where
          vpc_id = 'vpc-9d7ae1e7'
        group by
          availability_zone
        order by
          availability_zone
      EOQ
      type  = "column"
      width = 4
    }


    table {
      sql   = query.aws_vpc_subnets_for_vpc.sql
      width = 6
    }

  }







  container {
      title = "Routing"

    hierarchy {
      sql   = query.aws_vpc_routes_for_vpc_sankey.sql
    }



    table {
      title = "Route Tables"
      sql   = query.aws_vpc_route_tables_for_vpc.sql
      width = 6
    }


    table {
      title = "Routes"
      sql   = query.aws_vpc_routes_for_vpc.sql
      width = 6
    }

  }



  container {
    title = "Peering Connections"

    # table {
    #   sql = query.aws_vpc_peers_for_vpc_sankey.sql
    # }

    hierarchy {
      title = "Peering Connections"
      width = 6
      sql   = query.aws_vpc_peers_for_vpc_sankey.sql

      category "failed" {
        color = "red"
      }

      category "active" {
        color = "green"
      }
    }


    table {
      title = "Peering Connections"
      sql   = query.aws_vpc_peers_for_vpc.sql
    }
  }

  container {
    title = "NACLs"

    hierarchy {
      title = "Ingress NACLS"
      width = 6
      sql   = query.aws_ingress_nacl_for_vpc_sankey.sql

      category "deny" {
        color = "red"
      }

      category "allow" {
        color = "green"
      }
    }

    hierarchy {
      title = "Egress NACLS"
      width = 6
      sql   = query.aws_egress_nacl_for_vpc_sankey.sql

      category "deny" {
        color = "red"
      }

      category "allow" {
        color = "green"
      }
    }

  }




  container {
      title = "Gateways & Endpoints"
      table {
      title = "VPC Endpoints"

      sql   = query.aws_vpc_endpoints_for_vpc.sql
      width = 6
    }

    table {
      title = "Gateways"
      sql   = query.aws_vpc_gateways_for_vpc.sql
      width = 6
    }


  }

  container {
    title = "Security Groups"
    table {
      sql   = query.aws_vpc_security_groups_for_vpc.sql
      width = 4
    }
  }
}