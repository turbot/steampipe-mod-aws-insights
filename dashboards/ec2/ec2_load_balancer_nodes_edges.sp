# TODO: These should be cleaned up and moved into ec2.sp

edge "ec2_load_balancer_listener_to_ec2_lb" {
  title = "listener for"

  sql = <<-EOQ
    select
      lblistener.arn as from_id,
      $1 as to_id
    from
      aws_ec2_load_balancer_listener lblistener
    where
      lblistener.arn = any($1)
  EOQ

  param "ec2_load_balancer_listener_arns" {}
}

edge "ec2_alb_to_target_group" {
  title = "target group"

  sql = <<-EOQ
    select
      lb_arns as from_id,
      tg.target_group_arn as to_id
    from
      aws_ec2_target_group tg,
      jsonb_array_elements_text(tg.load_balancer_arns) as lb_arns
    where
      lb_arns = any($1);
  EOQ

  param "ec2_application_load_balancer_arns" {}
}

edge "ec2_glb_to_target_group" {
  title = "target group"

  sql = <<-EOQ
    select
      lb_arns as from_id,
      tg.target_group_arn as to_id
    from
      aws_ec2_target_group tg,
      jsonb_array_elements_text(tg.load_balancer_arns) as lb_arns
    where
      lb_arns = any($1);
  EOQ

  param "ec2_gateway_load_balancer_arns" {}
}

edge "ec2_nlb_to_target_group" {
  title = "target group"

  sql = <<-EOQ
    select
      lb_arns as from_id,
      tg.target_group_arn as to_id
    from
      aws_ec2_target_group tg,
      jsonb_array_elements_text(tg.load_balancer_arns) as lb_arns
    where
      lb_arns = any($1);
  EOQ

  param "ec2_gateway_load_balancer_arns" {}
}
