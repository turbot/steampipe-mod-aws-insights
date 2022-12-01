dashboard "vpc_detail" {

  title         = "AWS VPC Detail"
  documentation = file("./dashboards/vpc/docs/vpc_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "vpc_id" {
    title = "Select a VPC:"
    query = query.vpc_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.vpc_num_ips_for_vpc
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

    card {
      width = 2
      query = query.subnet_count_for_vpc
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

    card {
      width = 2
      query = query.vpc_is_default
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

    card {
      width = 2
      query = query.flow_logs_count_for_vpc
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

      with "vpc_flow_logs" {
        sql = <<-EOQ
          select
            flow_log_id as flow_log_id
          from
            aws_vpc_flow_log
          where
            resource_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      with "vpc_subnets" {
        sql = <<-EOQ
          select
            subnet_id as subnet_id
          from
            aws_vpc_subnet
          where
            vpc_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      with "vpc_security_groups" {
        sql = <<-EOQ
          select
            group_id as security_group_id
          from
            aws_vpc_security_group
          where
            vpc_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      with "ec2_instances" {
        sql = <<-EOQ
          select
            arn as instance_arn
          from
            aws_ec2_instance
          where
            vpc_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      with "lambda_functions" {
        sql = <<-EOQ
          select
            arn as function_arn
          from
            aws_lambda_function
          where
            vpc_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      with "ec2_application_load_balancers" {
        sql = <<-EOQ
          select
            arn as alb_arn
          from
            aws_ec2_application_load_balancer
          where
            vpc_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      with "ec2_classic_load_balancers" {
        sql = <<-EOQ
          select
            arn as clb_arn
          from
            aws_ec2_classic_load_balancer
          where
            vpc_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      with "ec2_network_load_balancers" {
        sql = <<-EOQ
          select
            arn as nlb_arn
          from
            aws_ec2_network_load_balancer
          where
            vpc_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      with "ec2_gateway_load_balancers" {
        sql = <<-EOQ
          select
            arn as glb_arn
          from
            aws_ec2_gateway_load_balancer
          where
            vpc_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      with "rds_db_instances" {
        sql = <<-EOQ
          select
            arn as rds_instance_arn
          from
            aws_rds_db_instance
          where
            vpc_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      with "redshift_clusters" {
        sql = <<-EOQ
          select
            arn as redshift_cluster_arn
          from
            aws_redshift_cluster
          where
            vpc_id = $1;
        EOQ

        args = [self.input.vpc_id.value]
      }

      nodes = [
        node.vpc_vpc,
        node.vpc_flow_log,
        node.vpc_subnet,
        node.vpc_security_group,
        node.ec2_instance,
        node.lambda_function,
        node.ec2_application_load_balancer,
        node.ec2_network_load_balancer,
        node.ec2_classic_load_balancer,
        node.ec2_gateway_load_balancer,
        node.rds_db_instance,
        node.redshift_cluster,

        node.vpc_s3_access_point,
        node.vpc_peered_vpc,
        node.vpc_az,
        node.vpc_igw,
        node.vpc_az_route_table,
        node.vpc_vcp_endpoint,
        node.vpc_transit_gateway,
        node.vpc_nat_gateway,
        node.vpc_vpn_gateway,
      ]

      edges = [
        edge.vpc_to_az,
        edge.vpc_to_vpc_flow_log,
        edge.vpc_az_to_vpc_subnet,
        edge.vpc_to_igw,
        edge.vpc_subnet_to_route_table,
        edge.vpc_to_vpc_route_table,
        edge.vpc_subnet_to_endpoint,
        edge.vpc_to_transit_gateway,
        edge.vpc_subnet_to_nat_gateway,
        edge.vpc_to_vpn_gateway,
        edge.vpc_to_vpc_security_group,

        edge.vpc_subnet_to_instance,
        edge.vpc_subnet_to_lambda,
        edge.vpc_subnet_to_ec2_alb,
        edge.vpc_subnet_to_ec2_nlb,
        edge.vpc_subnet_to_ec2_clb,
        edge.vpc_subnet_to_ec2_glb,
        edge.vpc_subnet_to_rds_instance,
        edge.vpc_to_s3_access_point,
        edge.vpc_peered_vpc
      ]

      args = {
        vpc_id                             = self.input.vpc_id.value
        vpc_vpc_ids                        = [self.input.vpc_id.value]
        vpc_security_group_ids             = with.vpc_security_groups.rows[*].security_group_id
        vpc_subnet_ids                     = with.vpc_subnets.rows[*].subnet_id
        ec2_classic_load_balancer_arns     = with.ec2_classic_load_balancers.rows[*].clb_arn
        ec2_application_load_balancer_arns = with.ec2_application_load_balancers.rows[*].alb_arn
        ec2_network_load_balancer_arns     = with.ec2_network_load_balancers.rows[*].nlb_arn
        ec2_gateway_load_balancer_arns     = with.ec2_gateway_load_balancers.rows[*].glb_arn
        ec2_instance_arns                  = with.ec2_instances.rows[*].instance_arn
        redshift_cluster_arns              = with.redshift_clusters.rows[*].redshift_cluster_arn
        lambda_function_arns               = with.lambda_functions.rows[*].function_arn
        rds_db_instance_arns               = with.rds_db_instances.rows[*].rds_instance_arn
        vpc_flow_log_ids                   = with.vpc_flow_logs.rows[*].flow_log_id
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
        query = query.vpc_overview
        args = {
          vpc_id = self.input.vpc_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.vpc_tags
        args = {
          vpc_id = self.input.vpc_id.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "CIDR Blocks"
        query = query.vpc_cidr_blocks
        args = {
          vpc_id = self.input.vpc_id.value
        }
      }

      table {
        title = "DHCP Options"
        query = query.vpc_dhcp_options
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
      query = query.vpc_subnet_by_az
      args = {
        vpc_id = self.input.vpc_id.value
      }

    }

    table {
      query = query.vpc_subnets_for_vpc
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
        node.vpc_routing_vpc_node,
        node.vpc_routing_subnet_node,
        node.vpc_routing_cidr_node,
        node.vpc_routing_gateway_node
      ]

      edges = [
        edge.vpc_routing_subnet_vpc_to_cidr_edge,
        edge.vpc_routing_cidr_to_gateway_edge
      ]

      args = {
        vpc_id = self.input.vpc_id.value
      }

    }

    table {
      title = "Route Tables"
      query = query.vpc_route_tables_for_vpc
      width = 6
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

    table {
      title = "Routes"
      query = query.vpc_routes_for_vpc
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
      query = query.vpc_peers_for_vpc
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
      query = query.ingress_nacl_for_vpc_sankey
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }


    flow {
      base  = flow.nacl_flow
      title = "Egress NACLs"
      width = 6
      query = query.egress_nacl_for_vpc_sankey
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }


  }

  container {

    title = "Gateways & Endpoints"

    table {
      title = "VPC Endpoints"

      query = query.vpc_endpoints_for_vpc
      width = 6
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

    table {
      title = "Gateways"
      query = query.vpc_gateways_for_vpc
      width = 6
      args = {
        vpc_id = self.input.vpc_id.value
      }
    }

  }

  container {

    title = "Security Groups"

    table {
      query = query.vpc_security_groups_for_vpc
      width = 12
      args = {
        vpc_id = self.input.vpc_id.value
      }

      column "Group Name" {
        href = "${dashboard.vpc_security_group_detail.url_path}?input.security_group_id={{.'Group ID' | @uri}}"
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

query "vpc_input" {
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

query "subnet_count_for_vpc" {
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

query "vpc_is_default" {
  sql = <<-EOQ
    select
      'Default VPC' as label,
      case when not is_default then 'Ok' else 'Default VPC' end as value,
      case when not is_default then 'ok' else 'alert' end as type
    from
      aws_vpc
    where
      vpc_id = $1;
  EOQ

  param "vpc_id" {}
}

query "vpc_num_ips_for_vpc" {
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

query "flow_logs_count_for_vpc" {
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

query "vpc_subnets_for_vpc" {
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

query "vpc_security_groups_for_vpc" {
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

query "vpc_endpoints_for_vpc" {
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

query "vpc_route_tables_for_vpc" {
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

query "vpc_routes_for_vpc" {
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

query "vpc_peers_for_vpc" {
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

query "vpc_gateways_for_vpc" {
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

query "ingress_nacl_for_vpc_sankey" {
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

query "egress_nacl_for_vpc_sankey" {
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

query "vpc_overview" {
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

query "vpc_tags" {
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

query "vpc_cidr_blocks" {
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

query "vpc_dhcp_options" {
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

query "vpc_subnet_by_az" {
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


node "vpc_routing_subnet_node" {
  category = category.vpc_subnet

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

node "vpc_routing_vpc_node" {
  category = category.vpc_subnet

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

node "vpc_routing_cidr_node" {
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

edge "vpc_routing_subnet_vpc_to_cidr_edge" {
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

node "vpc_routing_gateway_node" {
  category = category.vpc_internet_gateway

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

edge "vpc_routing_cidr_to_gateway_edge" {

  title = "gateway"
  sql   = <<-EOQ
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


// Graph queries
node "vpc_az" {
  category = category.availability_zone

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
      vpc_id = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_az" {
  title = "az"

  sql = <<-EOQ
    select
      distinct on (availability_zone)
      vpc_id as from_id,
      availability_zone as to_id
    from
      aws_vpc_subnet
    where
      vpc_id = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_az_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      availability_zone as from_id,
      subnet_id as to_id
    from
      aws_vpc_subnet
    where
      vpc_id = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}

node "vpc_igw" {
  category = category.vpc_internet_gateway

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
      a ->> 'VpcId' = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_igw" {
  title = "vpc"

  sql = <<-EOQ
    select
      a ->> 'VpcId' as to_id,
      i.internet_gateway_id as from_id
    from
      aws_vpc_internet_gateway as i,
      jsonb_array_elements(attachments) as a
    where
      a ->> 'VpcId' = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

node "vpc_az_route_table" {
  category = category.vpc_route_table

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
      vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_route_table" {
  title = "route table"

  sql = <<-EOQ
    select
       a ->> 'SubnetId' as to_id,
      rt.route_table_id as from_id
      from
        aws_vpc_route_table as rt,
        jsonb_array_elements(associations) as a
      where
        rt.vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}


edge "vpc_to_vpc_route_table" {
  title = "route table"

  sql = <<-EOQ
    select
      rt.vpc_id as from_id,
      rt.route_table_id as to_id
      from
        aws_vpc_route_table as rt,
        jsonb_array_elements(associations) as a
      where
        rt.vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}


node "vpc_vcp_endpoint" {
  category = category.vpc_endpoint

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
      vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_endpoint" {
  title = "vpc endpoint"

  sql = <<-EOQ
    select
      s as from_id,
      e.vpc_endpoint_id as to_id
    from
      aws_vpc_endpoint as e,
      jsonb_array_elements_text(e.subnet_ids) as s
    where
      e.vpc_id = any($1)
    union
    select
      vpc_id as from_id,
      vpc_endpoint_id as to_id
    from
      aws_vpc_endpoint as e
    where
      jsonb_array_length(subnet_ids) = 0
      and vpc_id = any($1);

  EOQ

  param "vpc_vpc_ids" {}
}

node "vpc_transit_gateway" {
  category = category.ec2_transit_gateway

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
      t.resource_id = any($1) and resource_type = 'vpc';
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_transit_gateway" {
  title = "transit_gateway"

  sql = <<-EOQ
    select
      resource_id as to_id,
      transit_gateway_id as from_id
    from
      aws_ec2_transit_gateway_vpc_attachment
      where resource_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

node "vpc_nat_gateway" {
  category = category.vpc_nat_gateway

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
      vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_nat_gateway" {
  title = "nat gateway"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      arn as to_id
    from
      aws_vpc_nat_gateway
    where
      vpc_id = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}

node "vpc_vpn_gateway" {
  category = category.vpc_vpn_gateway

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
      a ->> 'VpcId' = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_vpn_gateway" {
  title = "vpn gateway"

  sql = <<-EOQ
    select
      a ->> 'VpcId' as to_id,
      g.vpn_gateway_id as from_id
    from
      aws_vpc_vpn_gateway as g,
      jsonb_array_elements(vpc_attachments) as a
    where
      a ->> 'VpcId' = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      vpc_vpc_ids as from_id,
      vpc_security_group_ids as to_id
    from
      unnest($1::text[]) as vpc_vpc_ids,
      unnest($2::text[]) as vpc_security_group_ids
  EOQ

  param "vpc_vpc_ids" {}
  param "vpc_security_group_ids" {}
}

edge "vpc_peered_vpc" {
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

node "vpc_s3_access_point" {
  category = category.s3_access_point

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
      vpc_id  = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}


edge "vpc_to_s3_access_point" {
  title = "s3 access point"

  sql = <<-EOQ
    select
      vpc_id as from_id,
      access_point_arn as to_id
    from
      aws_s3_access_point
    where
      vpc_id = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}

node "vpc_peered_vpc" {
  category = category.vpc_vpc

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
        and requester_vpc_id = any($1)

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
        and accepter_vpc_id = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_vpc_flow_log" {
  title = "flow log"

  sql = <<-EOQ
    select
      vpc_vpc_ids as from_id,
      vpc_flow_log_ids as to_id
    from
      unnest($1::text[]) as vpc_flow_log_ids,
      unnest($2::text[]) as vpc_vpc_ids
  EOQ

  param "vpc_flow_log_ids" {}
  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_instance" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      arn as to_id
    from
      aws_ec2_instance
    where
      vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_lambda" {
  title = "lambda function"

  sql = <<-EOQ
    select
      s as from_id,
      l.arn as to_id
    from
      aws_lambda_function as l,
      jsonb_array_elements_text(l.vpc_subnet_ids) as s
    where
      l.vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

# In the below relation there could be multiple subnets associated to diffrent ec2_application_load_balancers. However it should not be all subnets to all ec2_application_load_balancers, to prevent this edge case; we have to write the query in below format without using unset
edge "vpc_subnet_to_ec2_alb" {
  title = "alb"

  sql = <<-EOQ
    select
      az ->> 'SubnetId' as from_id,
      a.arn as to_id
    from
      aws_ec2_application_load_balancer as a,
      jsonb_array_elements(availability_zones) as az
    where
      a.vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_ec2_nlb" {
  title = "nlb"

  sql = <<-EOQ
    select
      az ->> 'SubnetId' as from_id,
      n.arn as to_id
    from
      aws_ec2_network_load_balancer as n,
      jsonb_array_elements(availability_zones) as az
    where n.vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_ec2_clb" {
  title = "clb"

  sql = <<-EOQ
    select
      s as from_id,
      c.arn as to_id
    from
      aws_ec2_classic_load_balancer as c,
      jsonb_array_elements_text(subnets) as s
    where
      c.vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_ec2_glb" {
  title = "glb"

  sql = <<-EOQ
    select
      az ->> 'SubnetId' as from_id,
      g.arn as to_id
    from
      aws_ec2_gateway_load_balancer as g,
      jsonb_array_elements(availability_zones) as az
    where
      g.vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_rds_instance" {
  title = "rds instance"

  sql = <<-EOQ
    select
      s ->> 'SubnetIdentifier' as from_id,
      i.arn as to_id
    from
      aws_rds_db_instance as i,
      jsonb_array_elements(subnets) as s
    where
      i.vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}
