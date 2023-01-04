locals {
  ec2_common_tags = {
    service = "AWS/EC2"
  }
}

category "ec2_ami" {
  title = "EC2 AMI"
  href  = "/aws_insights.dashboard.ec2_ami_detail?input.ami={{.properties.'Image ID' | @uri}}"
  color = local.compute_color
  icon  = "developer_board"
}

category "ec2_application_load_balancer" {
  title = "EC2 Application Load Balancer"
  href  = "/aws_insights.dashboard.ec2_application_load_balancer_detail?input.alb={{.properties.'ARN' | @uri}}"
  icon  = "mediation"
  color = local.networking_color
}

category "ec2_autoscaling_group" {
  title = "EC2 Autoscaling Group"
  icon  = "library_add"
  color = local.compute_color
}

category "ec2_classic_load_balancer" {
  title = "EC2 Classic Load Balancer"
  href  = "/aws_insights.dashboard.ec2_classic_load_balancer_detail?input.clb={{.properties.'ARN' | @uri}}"
  icon  = "mediation"
  color = local.networking_color
}

category "ec2_gateway_load_balancer" {
  title = "EC2 Gateway Load Balancer"
  href  = "/aws_insights.dashboard.ec2_gateway_load_balancer_detail?input.glb={{.properties.'ARN' | @uri}}"
  icon  = "mediation"
  color = local.networking_color
}

category "ec2_instance" {
  title = "EC2 Instance"
  href  = "/aws_insights.dashboard.ec2_instance_detail?input.instance_arn={{.properties.'ARN' | @uri}}"
  icon  = "memory"
  color = local.compute_color
}

category "ec2_key_pair" {
  title = "EC2 Key Pair"
  icon  = "vpn_key"
  color = local.compute_color
}

category "ec2_launch_configuration" {
  title = "EC2 Launch Configuration"
  color = local.compute_color
  icon  = "rocket_launch"
}

category "ec2_load_balancer_listener" {
  title = "EC2 Load Balancer Listener"
  color = local.networking_color
  icon  = "hearing"
}

category "ec2_network_interface" {
  title = "EC2 Network Interface"
  href  = "/aws_insights.dashboard.ec2_network_interface_detail?input.network_interface_id={{.properties.'ID' | @uri}}"
  icon  = "settings_input_antenna"
  color = local.compute_color
}

category "ec2_network_load_balancer" {
  title = "EC2 Network Load Balancer"
  href  = "/aws_insights.dashboard.ec2_network_load_balancer_detail?input.nlb={{.properties.'ARN' | @uri}}"
  icon  = "mediation"
  color = local.networking_color
}

category "ec2_target_group" {
  title = "EC2 Target Group"
  icon  = "directions"
  color = local.networking_color
}

category "ec2_transit_gateway" {
  title = "EC2 Transit Gateway"
  icon  = "hub"
  color = local.networking_color
}
