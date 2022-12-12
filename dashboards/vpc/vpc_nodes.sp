node "ec2_availability_zone" {
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

node "ec2_transit_gateway" {
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

node "vpc_eip" {
  category = category.vpc_eip

  sql = <<-EOQ
  select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Allocation Id', allocation_id,
        'Association Id', association_id,
        'Public IP', public_ip,
        'Domain', domain,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_eip
    where
      arn = any($1 ::text[]);
  EOQ

  param "vpc_eip_arns" {}
}

node "vpc_endpoint" {
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
      vpc_endpoint_id = any($1);
  EOQ

  param "vpc_endpoint_ids" {}
}

node "vpc_flow_log" {
  category = category.vpc_flow_log

  sql = <<-EOQ
    select
      flow_log_id as id,
      title as title,
      jsonb_build_object(
        'Flow Log ID', flow_log_id,
        'Status', flow_log_status,
        'Creation Time', creation_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_flow_log
    where
      flow_log_id = any($1);
  EOQ

  param "vpc_flow_log_ids" {}
}

node "vpc_internet_gateway" {
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

node "vpc_nat_gateway" {
  category = category.vpc_nat_gateway

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'NAT Gateway ID', nat_gateway_id,
        'State', state,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_nat_gateway
    where
      arn = any($1);
  EOQ

  param "vpc_nat_gateway_arns" {}
}

node "vpc_network_acl" {
  category = category.vpc_network_acl

  sql = <<-EOQ
    select
      network_acl_id as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Is Default', is_default,
        'Association Id', a ->> 'NetworkAclAssociationId',
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_network_acl,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
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

node "vpc_route_table" {
  category = category.vpc_route_table

  sql = <<-EOQ
    select
      route_table_id as id,
      title as title,
      jsonb_build_object(
        'Owner ID', owner_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_route_table,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
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

node "vpc_security_group" {
  category = category.vpc_security_group

  sql = <<-EOQ
    select
      group_id as id,
      title as title,
      jsonb_build_object(
        'Group ID', group_id,
        'Description', description,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_security_group
    where
      group_id = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

node "vpc_subnet" {
  category = category.vpc_subnet

  sql = <<-EOQ
    select
      subnet_id as id,
      title as title,
      jsonb_build_object(
        'Subnet ID', subnet_id,
        'ARN', subnet_arn,
        'VPC ID', vpc_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_subnet
    where
      subnet_id = any($1 ::text[]);
  EOQ

  param "vpc_subnet_ids" {}
}

node "vpc_vpc" {
  category = category.vpc_vpc

  sql = <<-EOQ
    select
      vpc_id as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'VPC ID', vpc_id,
        'Is Default', is_default,
        'State', state,
        'CIDR Block', cidr_block,
        'DHCP Options ID', dhcp_options_id,
        'Owner ID', owner_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc
    where
      vpc_id = any($1 ::text[]);
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
