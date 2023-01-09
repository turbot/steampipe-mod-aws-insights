edge "codepipeline_pipeline_deploy_to_s3_bucket" {
  title = "deploys to"

  sql = <<-EOQ
    select
      'pipeline_deploy' as from_id,
      arn as to_id
    from
      aws_s3_bucket
    where
      name in
      (
        select
          a -> 'Configuration' ->> 'BucketName' as bucket_name
        from
          aws_codepipeline_pipeline,
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Deploy'
          and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
          and arn = any($1)
      );
  EOQ

  param "codepipeline_pipeline_arns" {}
}

edge "codepipeline_pipeline_build_to_codebuild_project" {
  title = "codebuild project"

  sql = <<-EOQ
    select
      'pipeline_build' as from_id,
      arn as to_id
    from
      aws_codebuild_project
    where
      arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codepipeline_pipeline_source_to_codecommit_repository" {
  title = "source provider"

  sql = <<-EOQ
    select
      'pipeline_source' as from_id,
      arn as to_id
    from
      aws_codecommit_repository
    where
      arn = any($1);
  EOQ

  param "codecommit_repository_arns" {}
}

edge "codepipeline_pipeline_deploy_to_codedeploy_app" {
  title = "deploys to"

  sql = <<-EOQ
  select
      'pipeline_deploy' as from_id,
      app.arn as to_id
    from
      aws_codedeploy_app as app,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Deploy'
      and a -> 'ActionTypeId' ->> 'Provider' = 'CodeDeploy'
      and a -> 'Configuration' ->> 'ApplicationName' = app.application_name
      and p.arn = any($1);
  EOQ

  param "codepipeline_pipeline_arns" {}
}

edge "codepipeline_pipeline_source_to_ecr_repository" {
  title = "source provider"

  sql = <<-EOQ
    select
      'pipeline_source' as from_id,
      arn as to_id
    from
      aws_ecr_repository
    where
      arn = any($1);
  EOQ

  param "ecr_repository_arns" {}
}

edge "codepipeline_pipeline_source_to_s3_bucket" {
  title = "source provider"

  sql = <<-EOQ
    select
      'pipeline_source' as from_id,
      arn as to_id
    from
      aws_s3_bucket
    where
      name in
      (
        select
          a -> 'Configuration' ->> 'S3Bucket' as bucket_name
        from
          aws_codepipeline_pipeline,
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Source'
          and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
          and arn = any($1)
      );
  EOQ

  param "codepipeline_pipeline_arns" {}
}

edge "codepipeline_pipeline_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      p.arn as from_id,
      k.arn as to_id
    from
      aws_codepipeline_pipeline as p,
      aws_kms_key as k,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasArn' = p.encryption_key ->> 'Id'
      and p.arn = any($1);
  EOQ

  param "codepipeline_pipeline_arns" {}
}

edge "codepipeline_pipeline_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      p.arn as from_id,
      r.arn as to_id
    from
      aws_iam_role as r,
      aws_codepipeline_pipeline as p
    where
      r.arn = p.role_arn
      and p.arn = any($1);
  EOQ

  param "codepipeline_pipeline_arns" {}
}
