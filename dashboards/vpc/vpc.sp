locals {
  vpc_common_tags = {
    service = "AWS/VPC"
  }
}

category "vpc_eip" {
  title = "VPC EIP"
  color = local.networking_color
  href  = "/aws_insights.dashboard.vpc_eip_detail?input.eip_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:EIP"
}

category "vpc_endpoint" {
  title = "VPC Endpoint"
  color = local.networking_color
  icon  = "text:Endpoint"
}

category "vpc_flow_log" {
  title = "VPC Flow Log"
  href  = "/aws_insights.dashboard.vpc_flow_logs_detail?input.flow_log_id={{.properties.'Flow Log ID' | @uri}}"
  color = local.networking_color
  icon  = "text:FL"
}

category "vpc_internet_gateway" {
  title = "VPC Internet Gateway"
  icon  = "text:IGW"
  color = local.networking_color
}

category "vpc_nat_gateway" {
  title = "VPC NAT Gateway"
  icon  = "text:NAT"
  color = local.networking_color
}

category "vpc_network_acl" {
  title = "VPC Network ACL"
  icon  = "text:ACL"
  color = local.networking_color
}

category "vpc_peering_connection" {
  title = "VPC Peering Connection"
  color = local.networking_color
  icon  = "text:Peering"
}

category "vpc_route_table" {
  title = "VPC Route Table"
  icon  = "heroicons-outline:arrows-right-left"
  color = local.networking_color
}

category "vpc_security_group" {
  title = "VPC Security Group"
  href  = "/aws_insights.dashboard.vpc_security_group_detail?input.security_group_id={{.properties.'Group ID' | @uri}}"
  icon  = "heroicons-outline:lock-closed"
  color = local.networking_color
}

category "vpc_subnet" {
  title = "VPC Subnet"
  href  = "/aws_insights.dashboard.vpc_subnet_detail?input.subnet_id={{.properties.'Subnet ID' | @uri}}"
  icon  = "heroicons-outline:share"
  color = local.networking_color
}

category "vpc_vpc" {
  title = "VPC"
  href  = "/aws_insights.dashboard.vpc_detail?input.vpc_id={{.properties.'VPC ID' | @uri}}"
  icon  = "heroicons-outline:cloud"
  color = local.networking_color
}

category "vpc_vpn_gateway" {
  title = "VPC VPN Gateway"
  icon  = "text:VPN"
  color = local.networking_color
}
