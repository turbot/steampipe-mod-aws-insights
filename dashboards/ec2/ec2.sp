locals {
  ec2_common_tags = {
    service = "AWS/EC2"
  }
}

# TODO: Why do some categories have "href" but others don't?

category "aws_ec2_ami" {
  title = "EC2 AMI"
  href  = "aws_insights.dashboard.aws_ec2_ami_detail?input.ami={{.properties.'Image ID' | @uri}}"
  color = local.compute_color
  icon  = "text:image"
}

category "aws_ec2_application_load_balancer" {
  title = "EC2 Application Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_application_load_balancer_detail?input.alb={{.properties.'ARN' | @uri}}"
  icon  = "text:ALB"
  color = local.networking_color
}

category "aws_ec2_autoscaling_group" {
  title = "EC2 Autoscaling Group"
  icon  = "square2stack"
  color = local.compute_color
}

category "aws_ec2_classic_load_balancer" {
  title = "EC2 Classic Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_classic_load_balancer_detail?input.clb={{.properties.'ARN' | @uri}}"
  icon  = "text:CLB"
  color = local.networking_color
}

category "aws_ec2_gateway_load_balancer" {
  title = "EC2 Gateway Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_gateway_load_balancer_detail?input.glb={{.properties.'ARN' | @uri}}"
  icon  = "text:GLB"
  color = local.networking_color
}

category "aws_ec2_instance" {
  title = "EC2 Instance"
  href  = "/aws_insights.dashboard.aws_ec2_instance_detail?input.instance_arn={{.properties.'ARN' | @uri}}"
  icon  = "cpuchip"
  color = local.compute_color
}

category "aws_ec2_key_pair" {
  title = "EC2 Key Pair"
  icon  = "key"
  color = local.compute_color
}

category "aws_ec2_launch_configuration" {
  title = "EC2 Launch Configuration"
  color = local.compute_color
  icon  = "newspaper"
}

category "aws_ec2_load_balancer_listener" {
  title = "EC2 Load Balancer Listener"
  color = local.networking_color
  icon  = "text:LBL"
}

category "aws_ec2_network_interface" {
  title = "EC2 Network Interface"
  href  = "/aws_insights.dashboard.aws_ec2_network_interface_detail?input.network_interface_id={{.properties.'Interface ID' | @uri}}"
  icon  = "text:ENI"
  color = local.compute_color
}

category "aws_ec2_network_load_balancer" {
  title = "EC2 Network Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_network_load_balancer_detail?input.nlb={{.properties.'ARN' | @uri}}"
  icon  = "text:NLB"
  color = local.networking_color
}

category "aws_ec2_target_group" {
  title = "EC2 Target Group"
  icon  = "arrowdownonsquare"
  color = local.networking_color
}

category "aws_ec2_transit_gateway" {
  title = "EC2 Transit Gateway"
  icon  = "arrows-right-left"
  color = local.networking_color
}
