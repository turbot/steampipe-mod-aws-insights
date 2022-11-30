edge "ecs_cluster_to_ec2_instance" {
  title = "container instance"

  sql = <<-EOQ
    select
      cluster_arns as from_id,
      instance_arns as to_id
    from
      unnest($1::text[]) as cluster_arns,
     unnest($2::text[]) as instance_arns
  EOQ

  param "ecs_cluster_arns" {}
  param "instance_arns" {}
}
