locals {
  ecr_common_tags = {
    service = "AWS/ECR"
  }
}

category "ecr_image" {
  title = "ECR Image"
  color = local.containers_color
  icon  = "text:Image"
}

category "ecr_repository" {
  title = "ECR Repository"
  color = local.containers_color
  href  = "/aws_insights.dashboard.ecr_repository_detail?input.ecr_repository_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:ECR"
}
