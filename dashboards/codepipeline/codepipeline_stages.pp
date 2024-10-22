graph "codepipeline_pipeline_structures" {
  param "codepipeline_pipeline_arns" {}

  node "codepipeline_pipeline_source" {
    category = category.codepipeline_pipeline_source

    sql = <<-EOQ
    select
      'pipeline_source' as id,
      'Source' as title
  EOQ
  }

  node "codepipeline_pipeline_build" {
    category = category.codepipeline_pipeline_build

    sql = <<-EOQ
    select
      'pipeline_build' as id,
      'Build' as title
  EOQ
  }

  node "codepipeline_pipeline_deploy" {
    category = category.codepipeline_pipeline_deploy

    sql = <<-EOQ
    select
      'pipeline_deploy' as id,
      'deploy' as title
  EOQ
  }

  edge "codepipeline_pipeline_to_codepipeline_pipeline_source" {
    title = "source"

    sql = <<-EOQ
    select
      arn as from_id,
      'pipeline_source' as to_id
    from
      aws_codepipeline_pipeline
    where
      arn = any($1);
  EOQ

    args = [param.codepipeline_pipeline_arns]
  }

  edge "codepipeline_pipeline_to_codepipeline_pipeline_build" {
    title = "build"

    sql = <<-EOQ
    select
      arn as from_id,
      'pipeline_build' as to_id
    from
      aws_codepipeline_pipeline
    where
      arn = any($1);
  EOQ

    args = [param.codepipeline_pipeline_arns]
  }

  edge "codepipeline_pipeline_to_codepipeline_pipeline_deploy" {
    title = "deploy"

    sql = <<-EOQ
    select
      arn as from_id,
      'pipeline_deploy' as to_id
    from
      aws_codepipeline_pipeline
    where
      arn = any($1);
  EOQ

    args = [param.codepipeline_pipeline_arns]
  }

}
