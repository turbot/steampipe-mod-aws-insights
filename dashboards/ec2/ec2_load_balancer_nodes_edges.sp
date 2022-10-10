node "aws_ec2_lb_to_target_group_node" {
  category = category.aws_ec2_target_group

  sql = <<-EOQ
    select
      tg.target_group_arn as id,
      tg.title as title,
      jsonb_build_object(
        'Group Name', tg.target_group_name,
        'ARN', tg.target_group_arn,
        'Account ID', tg.account_id,
        'Region', tg.region
      ) as properties
    from
      aws_ec2_target_group tg
    where
      $1 in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      );
  EOQ

  param "arn" {}
}

edge "aws_ec2_lb_to_target_group_edge" {
  title = "target group"

  sql = <<-EOQ
    select
      $1 as from_id,
      tg.target_group_arn as to_id,
      jsonb_build_object(
        'Account ID', tg.account_id
      ) as properties
    from
      aws_ec2_target_group tg
    where
      $1 in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      );
  EOQ

  param "arn" {}
}

node "aws_ec2_lb_to_ec2_instance_node" {
  category = category.aws_ec2_instance

  sql = <<-EOQ
    select
      instance.instance_id as id,
      instance.title as title,
      jsonb_build_object(
        'Instance ID', instance.instance_id,
        'ARN', instance.arn,
        'Account ID', instance.account_id,
        'Region', instance.region
      ) as properties
    from
      aws_ec2_target_group tg,
      aws_ec2_instance instance,
      jsonb_array_elements(tg.target_health_descriptions) thd
    where
      instance.instance_id = thd -> 'Target' ->> 'Id'
      and $1 in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      );
  EOQ

  param "arn" {}
}

edge "aws_ec2_lb_to_ec2_instance_edge" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      tg.target_group_arn as from_id,
      instance.instance_id as to_id,
      jsonb_build_object(
        'Account ID', instance.account_id,
        'Health Check Port', thd['HealthCheckPort'],
        'Health Check State', thd['TargetHealth']['State']
      ) as properties
    from
      aws_ec2_target_group tg,
      aws_ec2_instance instance,
      jsonb_array_elements(tg.target_health_descriptions) thd
    where
      instance.instance_id = thd -> 'Target' ->> 'Id'
      and $1 in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      );
  EOQ

  param "arn" {}
}

node "aws_ec2_lb_from_ec2_load_balancer_listener_node" {
  category = category.aws_ec2_load_balancer_listener

  sql = <<-EOQ
    select
      lblistener.arn as id,
      lblistener.title as title,
      jsonb_build_object(
        'ARN', lblistener.arn,
        'Account ID', lblistener.account_id,
        'Region', lblistener.region,
        'Protocol', lblistener.protocol,
        'Port', lblistener.port,
        'SSL Policy', coalesce(lblistener.ssl_policy, 'None')
      ) as properties
    from
      aws_ec2_load_balancer_listener lblistener
    where
      lblistener.load_balancer_arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ec2_lb_from_ec2_load_balancer_listener_edge" {
  title = "listens with"

  sql = <<-EOQ
    select
      lblistener.arn as from_id,
      $1 as to_id,
      jsonb_build_object(
        'Account ID', lblistener.account_id
      ) as properties
    from
      aws_ec2_load_balancer_listener lblistener
    where
      lblistener.load_balancer_arn = $1
  EOQ

  param "arn" {}
}
