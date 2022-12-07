edge "vpc_nat_gateway_to_ec2_network_interface" {
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

  param "ec2_network_interface_ids" {}
}

edge "vpc_security_group_to_dax_subnet_group" {
  title = "subnet group"
  sql   = <<-EOQ
    select
      sg ->> 'SecurityGroupIdentifier' as from_id,
      subnet_group as to_id
    from
      aws_dax_cluster,
      jsonb_array_elements(security_groups) as sg
    where
      arn = any($1);
  EOQ

  param "dax_cluster_arns" {}
}

edge "vpc_subnet_to_vpc_vpc" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      vpc_id as to_id
    from
      aws_vpc_subnet
    where
      subnet_id = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}