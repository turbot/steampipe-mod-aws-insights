node "ec2_application_load_balancer" {
  category = category.ec2_application_load_balancer

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'State Code', state_code,
        'Account ID', account_id,
        'VPC ID', vpc_id,
        'Region', region,
        'DNS Name', dns_name
      ) as properties
    from
      aws_ec2_application_load_balancer
    where
      arn = any($1);
  EOQ

  param "ec2_application_load_balancer_arns" {}
}

node "ec2_classic_load_balancer" {
  category = category.ec2_classic_load_balancer

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'VPC ID', vpc_id,
        'Scheme', scheme,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_ec2_classic_load_balancer
    where
      arn = any($1);
  EOQ

  param "ec2_classic_load_balancer_arns" {}
}

node "ec2_gateway_load_balancer" {
  category = category.ec2_gateway_load_balancer

  sql = <<-EOQ
   select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'State Code', state_code,
        'Account ID', account_id,
        'Region', region,
        'DNS Name', dns_name,
        'VPC ID', vpc_id
      ) as properties
    from
      aws_ec2_gateway_load_balancer
    where
      arn = any($1 ::text[]);
  EOQ

  param "ec2_gateway_load_balancer_arns" {}
}

node "ec2_instance" {
  category = category.ec2_instance

  sql = <<-EOQ
    select
      arn as id,
      title,
      jsonb_build_object(
        'Instance ID', instance_id,
        'Name', tags ->> 'Name',
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_instance
    where
      arn = any($1);
  EOQ

  param "ec2_instance_arns" {}
}

node "ec2_network_interface" {
  category = category.ec2_network_interface

  sql = <<-EOQ
    select
      network_interface_id as id,
      title as title,
      jsonb_build_object(
        'ID', network_interface_id,
        'Interface Type', interface_type,
        'Status', status,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_network_interface
    where
      network_interface_id = any($1 ::text[]);
  EOQ

  param "ec2_network_interface_ids" {}
}

node "ec2_network_load_balancer" {
  category = category.ec2_network_load_balancer

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'VPC ID', vpc_id,
        'State Code', state_code,
        'Account ID', account_id,
        'Region', region,
        'DNS Name', dns_name
      ) as properties
    from
      aws_ec2_network_load_balancer
    where
      arn = any($1);
  EOQ

  param "ec2_network_load_balancer_arns" {}
}

node "ec2_ami" {
  category = category.ec2_ami

  sql = <<-EOQ
    select
      image_id as id,
      title as title,
      jsonb_build_object(
        'Image ID', image_id,
        'Image Location', image_location,
        'State', state,
        'public', public::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_ami
    where
      image_id = any($1);
  EOQ

  param "ec2_ami_image_ids" {}
}

node "ec2_launch_configuration" {
  category = category.ec2_launch_configuration

  sql = <<-EOQ
    select
      launch_configuration_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', launch_configuration_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_launch_configuration
    where
      launch_configuration_arn = any($1);
  EOQ

  param "ec2_launch_configuration_arns" {}
}