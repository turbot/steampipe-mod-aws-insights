locals {
  vpc_common_tags = {
    service = "AWS/VPC"
  }
}

category "vpc_eip" {
  title = "VPC EIP"
  color = local.networking_color
  href  = "/aws_insights.dashboard.vpc_eip_detail?input.eip_arn={{.properties.'ARN' | @uri}}"
  icon  = "swipe_right_alt"
}

category "vpc_endpoint" {
  title = "VPC Endpoint"
  color = local.networking_color
  icon  = "pin_invoke"
}

category "vpc_flow_log" {
  title = "VPC Flow Log"
  color = local.networking_color
  href  = "/aws_insights.dashboard.vpc_flow_logs_detail?input.flow_log_id={{.properties.'Flow Log ID' | @uri}}"
  icon  = "export_notes"
}

category "vpc_internet_gateway" {
  title = "VPC Internet Gateway"
  color = local.networking_color
  icon  = "router"
}

category "vpc_nat_gateway" {
  title = "VPC NAT Gateway"
  color = local.networking_color
  icon  = "merge"
}

category "vpc_network_acl" {
  title = "VPC Network ACL"
  color = local.networking_color
  icon  = "rule"
}

category "vpc_peering_connection" {
  title = "VPC Peering Connection"
  color = local.networking_color
  icon  = "sync_alt"
}

category "vpc_route_table" {
  title = "VPC Route Table"
  color = local.networking_color
  icon  = "table_rows"
}

category "vpc_security_group" {
  title = "VPC Security Group"
  color = local.networking_color
  href  = "/aws_insights.dashboard.vpc_security_group_detail?input.security_group_id={{.properties.'Group ID' | @uri}}"
  icon  = "enhanced_encryption"
}

category "vpc_subnet" {
  title = "VPC Subnet"
  color = local.networking_color
  href  = "/aws_insights.dashboard.vpc_subnet_detail?input.subnet_id={{.properties.'Subnet ID' | @uri}}"
  icon  = "lan"
}

category "vpc_vpc" {
  title = "VPC"
  color = local.networking_color
  href  = "/aws_insights.dashboard.vpc_detail?input.vpc_id={{.properties.'VPC ID' | @uri}}"
  icon  = "cloud"
}

category "vpc_vpn_gateway" {
  title = "VPC VPN Gateway"
  color = local.networking_color
  icon  = "vpn_lock"
}
