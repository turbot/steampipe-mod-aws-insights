locals {
  codepipeline_common_tags = {
    service = "AWS/CodePipeline"
  }
}

category "codepipeline_pipeline" {
  title = "CodePipeline Pipeline"
  color = local.developer_tools_color
  href  = "/aws_insights.dashboard.codepipeline_pipeline_detail?input.pipeline_arn={{.properties.'ARN' | @uri}}"
  icon  = "valve"
}

category "codepipeline_pipeline_source" {
  title = "Pipeline Source"
  color = local.developer_tools_color
  icon  = "code_blocks"
}

category "codepipeline_pipeline_build" {
  title = "Pipeline Build"
  color = local.developer_tools_color
  icon  = "construction"
}

category "codepipeline_pipeline_deploy" {
  title = "Pipeline Deploy"
  color = local.developer_tools_color
  icon  = "published_with_changes"
}
