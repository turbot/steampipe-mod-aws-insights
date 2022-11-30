node "ecs_cluster" {
  category = category.ecs_cluster

  sql = <<-EOQ
   select
      cluster_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', cluster_arn,
        'Status', status,
        'Account ID', account_id,
        'Region', region,
        'Active Services Count', active_services_count,
        'Running Tasks Count', running_tasks_count
      ) as properties
    from
      aws_ecs_cluster
    where
      cluster_arn = any($1 ::text[]);
  EOQ

  param "ecs_cluster_arns" {}
}
