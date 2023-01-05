locals {
  ecs_common_tags = {
    service = "AWS/ECS"
  }
}

category "ecs_cluster" {
  title = "ECS Cluster"
  color = local.compute_color
  href  = "/aws_insights.dashboard.ecs_cluster_detail?input.ecs_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "token"
}

category "ecs_container_instance" {
  title = "ECS Container Instance"
  color = local.compute_color
  icon  = "memory"
}

category "ecs_service" {
  title = "ECS Service"
  color = local.compute_color
  href  = "/aws_insights.dashboard.ecs_service_detail?input.service_arn={{.properties.'ARN' | @uri}}"
  icon  = "settings_suggest"
}

category "ecs_task" {
  title = "ECS Task"
  color = local.compute_color
  icon  = "task_alt"
}

category "ecs_task_definition" {
  title = "ECS Tasks Definition"
  color = local.compute_color
  href  = "/aws_insights.dashboard.ecs_task_definition_detail?input.task_definition_arn={{.properties.'ARN' | @uri}}"
  icon  = "task"
}
