locals {
  ecr_common_tags = {
    service = "AWS/ECR"
  }
}

category "ecr_image" {
  title = "ECR Image"
  color = local.containers_color
  icon  = "image"
}

category "ecr_image_tag" {
  title = "ECR Image Tag"
  color = local.containers_color
  icon  = "sell"
}

category "ecr_repository" {
  title = "ECR Repository"
  color = local.containers_color
  href  = "/aws_insights.dashboard.ecr_repository_detail?input.ecr_repository_arn={{.properties.'ARN' | @uri}}"
  icon  = "photo-library"
}
