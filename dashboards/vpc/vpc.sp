locals {
  vpc_common_tags = {
    service = "AWS/VPC"
  }
}

category "aws_vpc" {
  title = "VPC"
  href  = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{.properties.'VPC ID' | @uri}}"
  icon  = "cloud" //"text:vpc"
  color = local.networking_color
}

category "aws_vpc_eip" {
  title = "VPC EIP"
  color = local.networking_color
  href  = "/aws_insights.dashboard.aws_vpc_eip_detail?input.eip_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:EIP"
}

category "aws_vpc_endpoint" {
  title = "VPC Endpoint"
  color = local.networking_color
  icon  = "text:Endpoint"
}

category "aws_vpc_flow_log" {
  title = "VPC Flow Log"
  href  = "/aws_insights.dashboard.aws_vpc_flow_logs_detail?input.flow_log_id={{.properties.'Flow Log ID' | @uri}}"
  color = local.networking_color
  icon  = "text:FL"
}

category "aws_vpc_internet_gateway" {
  title = "VPC Internet Gateway"
  icon  = "text:IGW"
  color = local.networking_color
}

category "aws_vpc_nat_gateway" {
  title = "VPC NAT Gateway"
  icon  = "text:NAT"
  color = local.networking_color
}

category "aws_vpc_network_acl" {
  title = "VPC Network ACL"
  icon  = "text:ACL"
  color = local.networking_color
}

category "aws_vpc_peering_connection" {
  title = "VPC Peering Connection"
  color = local.networking_color
  icon  = "text:Peering"
}

category "aws_vpc_route_table" {
  title = "VPC Route Table"
  icon  = "arrows-right-left"
  color = local.networking_color
}

category "aws_vpc_security_group" {
  title = "VPC Security Group"
  href  = "/aws_insights.dashboard.aws_vpc_security_group_detail?input.security_group_id={{.properties.'Group ID' | @uri}}"
  icon  = "lock-closed"
  color = local.networking_color
}

category "aws_vpc_subnet" {
  title = "VPC Subnet"
  href  = "/aws_insights.dashboard.aws_vpc_subnet_detail?input.subnet_id={{.properties.'Subnet ID' | @uri}}"
  icon  = "share"
  color = local.networking_color
}

category "aws_vpc_vpn_gateway" {
  title = "VPC VPN Gateway"
  icon  = "text:VPN"
  color = local.networking_color
}
