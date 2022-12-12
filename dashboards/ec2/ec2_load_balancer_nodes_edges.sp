# TODO: These should be cleaned up and moved into ec2.sp

edge "ec2_application_load_balancer_to_ec2_target_group" {
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

edge "ec2_gateway_load_balancer_to_ec2_target_group" {
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

edge "ec2_network_load_balancer_to_ec2_target_group" {
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

  param "ec2_network_load_balancer_arns" {}
}
