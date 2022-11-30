locals {
  ecs_common_tags = {
    service = "AWS/ECS"
  }
}

category "ecs_cluster" {
  title = "ECS Cluster"
  href  = "/aws_insights.dashboard.aws_ecs_cluster_detail?input.ecs_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:ECS"
  color = local.compute_color
}

category "aws_ecs_container_instance" {
  title = "ECS Container Instance"
  icon  = "text:ECS"
  color = local.compute_color
}

category "aws_ecs_service" {
  title = "ECS Service"
  color = local.compute_color
  icon  = "text:ECS"
  href  = "/aws_insights.dashboard.aws_ecs_service_detail?input.service_arn={{.properties.'ARN' | @uri}}"
}

category "aws_ecs_task" {
  title = "ECS Task"
  color = local.compute_color
  icon  = "text:Task"
}

category "aws_ecs_task_definition" {
  title = "ECS Tasks Definition"
  color = local.compute_color
  href  = "/aws_insights.dashboard.aws_ecs_task_definition_detail?input.task_definition_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:ECS"
}
