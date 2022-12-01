node "aws_ec2_classic_load_balancer_nodes" {
  category = category.aws_ec2_classic_load_balancer

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

  param "clb_arns" {}
}

node "aws_ec2_instance_nodes" {
  category = category.aws_ec2_instance

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

node "ec2_launch_configuration" {
  category = category.aws_ec2_launch_configuration

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

  param "launch_configuration_arns" {}
}