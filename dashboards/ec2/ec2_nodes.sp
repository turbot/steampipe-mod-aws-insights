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

  param "application_load_balancer_arns" {}
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

  param "classic_load_balancer_arns" {}
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

  param "glb_arns" {}
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

  param "instance_arns" {}
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

  param "eni_ids" {}
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

  param "network_load_balancer_arns" {}
}
