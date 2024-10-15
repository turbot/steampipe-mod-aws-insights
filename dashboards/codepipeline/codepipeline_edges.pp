edge "codepipeline_pipeline_build_to_codebuild_project" {
  title = "codebuild project"

  sql = <<-EOQ
    select
      'pipeline_build' as from_id,
      arn as to_id
    from
      aws_codebuild_project
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    where
      arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codepipeline_pipeline_deploy_to_appconfig_application" {
  title = "deploys to"

  sql = <<-EOQ
    select
      'pipeline_deploy' as from_id,
      arn as to_id
    from
      aws_appconfig_application
    where
      id in
      (
        select
          a -> 'Configuration' ->> 'Application'
        from
          aws_codepipeline_pipeline
          join unnest($1::text[]) as b on arn = b and account_id = split_part(b, ':', 5) and region = split_part(b, ':', 4),
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Deploy'
          and a -> 'ActionTypeId' ->> 'Provider' = 'AppConfig'
      );
  EOQ

  param "codepipeline_pipeline_arns" {}
}

edge "codepipeline_pipeline_deploy_to_cloudformation" {
  title = "deploys to"

  sql = <<-EOQ
    select
      'pipeline_deploy' as from_id,
      id as to_id
    from
      aws_cloudformation_stack
    where
      name in
      (
        select
          a -> 'Configuration' ->> 'StackName'
        from
          aws_codepipeline_pipeline
          join unnest($1::text[]) as b on arn = b and account_id = split_part(b, ':', 5) and region = split_part(b, ':', 4),
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Deploy'
          and a -> 'ActionTypeId' ->> 'Provider' = 'CloudFormation'
      );
  EOQ

  param "codepipeline_pipeline_arns" {}
}

edge "codepipeline_pipeline_deploy_to_codedeploy_app" {
  title = "deploys to"

  sql = <<-EOQ
  select
      'pipeline_deploy' as from_id,
      app.arn as to_id
    from
      aws_codedeploy_app as app,
      aws_codepipeline_pipeline as p
      join unnest($1::text[]) as b on p.arn = b and p.account_id = split_part(b, ':', 5) and p.region = split_part(b, ':', 4),
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Deploy'
      and a -> 'ActionTypeId' ->> 'Provider' = 'CodeDeploy'
      and a -> 'Configuration' ->> 'ApplicationName' = app.application_name;
  EOQ

  param "codepipeline_pipeline_arns" {}
}

edge "codepipeline_pipeline_deploy_to_ecs_cluster" {
  title = "deploys to"

  sql = <<-EOQ
    select
      'pipeline_deploy' as from_id,
      cluster_arn as to_id
    from
      aws_ecs_cluster
    where
      cluster_name in
      (
        select
          a -> 'Configuration' ->> 'ClusterName'
        from
          aws_codepipeline_pipeline
          join unnest($1::text[]) as b on arn = b and account_id = split_part(b, ':', 5) and region = split_part(b, ':', 4),
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Deploy'
          and a -> 'ActionTypeId' ->> 'Provider' = 'ECS'
      );
  EOQ

  param "codepipeline_pipeline_arns" {}
}

edge "codepipeline_pipeline_deploy_to_elastic_beanstalk_application" {
  title = "deploys to"

  sql = <<-EOQ
    select
      'pipeline_deploy' as from_id,
      arn as to_id
    from
      aws_elastic_beanstalk_application
    where
      name in
      (
        select
          a -> 'Configuration' ->> 'ApplicationName'
        from
          aws_codepipeline_pipeline
          join unnest($1::text[]) as b on arn = b and account_id = split_part(b, ':', 5) and region = split_part(b, ':', 4),
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Deploy'
          and a -> 'ActionTypeId' ->> 'Provider' = 'ElasticBeanstalk'
      );
  EOQ

  param "codepipeline_pipeline_arns" {}
}

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
          aws_codepipeline_pipeline
          join unnest($1::text[]) as b on arn = b and account_id = split_part(b, ':', 5) and region = split_part(b, ':', 4),
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

edge "codepipeline_pipeline_source_to_codecommit_repository" {
  title = "source provider"

  sql = <<-EOQ
    select
      'pipeline_source' as from_id,
      arn as to_id
    from
      aws_codecommit_repository
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "codecommit_repository_arns" {}
}

edge "codepipeline_pipeline_source_to_ecr_repository" {
  title = "source provider"

  sql = <<-EOQ
    select
      'pipeline_source' as from_id,
      arn as to_id
    from
      aws_ecr_repository
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
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
          aws_codepipeline_pipeline
          join unnest($1::text[]) as b on arn = b and account_id = split_part(b, ':', 5) and region = split_part(b, ':', 4),
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Source'
          and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
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
      aws_codepipeline_pipeline as p
      join unnest($1::text[]) as b on p.arn = b and p.account_id = split_part(b, ':', 5) and p.region = split_part(b, ':', 4),
      aws_kms_key as k,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasArn' = p.encryption_key ->> 'Id';
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
      join unnest($1::text[]) as a on p.arn = a and p.account_id = split_part(a, ':', 5) and p.region = split_part(a, ':', 4)
    where
      r.arn = p.role_arn;
  EOQ

  param "codepipeline_pipeline_arns" {}
}
