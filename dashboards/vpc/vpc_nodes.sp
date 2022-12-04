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
