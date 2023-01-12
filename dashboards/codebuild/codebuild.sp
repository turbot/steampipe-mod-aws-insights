locals {
  codebuild_common_tags = {
    service = "AWS/CodeBuild"
  }
}

category "codebuild_project" {
  title = "CodeBuild Project"
  color = local.developer_tools_color
  href  = "/aws_insights.dashboard.codebuild_project_detail?input.codebuild_project_arn={{.properties.'ARN' | @uri}}"
  icon  = "build"
}
