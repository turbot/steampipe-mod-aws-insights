locals {
  codepipeline_common_tags = {
    service = "AWS/CodePipeline"
  }
}

category "codepipeline_pipeline" {
  title = "CodePipeline Pipeline"
  color = local.developer_tools_color
  href  = "/aws_insights.dashboard.codepipeline_pipeline_detail?input.pipeline_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:CICD"
}