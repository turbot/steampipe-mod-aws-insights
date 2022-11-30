edge "ecs_cluster_to_ec2_instance" {
  title = "container instance"

  sql = <<-EOQ
    select
      cluster_arn as from_id,
      instance_arn as to_id
    from
      unnest($1::text[]) as cluster_arn,
     unnest($2::text[]) as instance_arn
  EOQ

  param "ecs_cluster_arns" {}
  param "instance_arns" {}
}
