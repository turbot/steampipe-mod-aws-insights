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

node "ecs_task_definition" {
  category = category.ecs_task_definition

  sql = <<-EOQ
    select
      task_definition_arn as id,
      title as title,
      jsonb_build_object(
        'ARN', task_definition_arn,
        'Status', status,
        'Image', d ->> 'Image',
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ecs_task_definition,
      jsonb_array_elements(container_definitions) as d
    where
      task_definition_arn = any($1)
  EOQ

  param "ecs_task_definition_arns" {}
}