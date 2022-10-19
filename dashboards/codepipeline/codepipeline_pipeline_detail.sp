dashboard "codepipeline_pipeline_detail" {

  title         = "AWS CodePipeline Pipeline Detail"
  documentation = file("./dashboards/codepipeline/docs/codepipeline_pipeline_detail.md")

  tags = merge(local.codepipeline_common_tags, {
    type = "Detail"
  })

  input "pipeline_arn" {
    title = "Select a pipeline:"
    query = query.aws_codepipeline_pipeline_input
    width = 4
  }

  container {

    card {
      query = query.aws_codepipeline_pipeline_encryption
      width = 2
      args = {
        arn = self.input.pipeline_arn.value
      }
    }

  }

  container {
    graph {
      type      = "graph"
      direction = "LR"
      base      = graph.aws_graph_categories
      query     = query.aws_codepipeline_pipeline_relationships_graph
      args = {
        arn = self.input.pipeline_arn.value
      }
      category "aws_codepipeline_pipeline" {}
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_codepipeline_pipeline_overview
        args = {
          arn = self.input.pipeline_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_codepipeline_pipeline_tags
        args = {
          arn = self.input.pipeline_arn.value
        }

      }
    }
    container {
      width = 6

      table {
        title = "Stages"
        query = query.aws_codepipeline_pipeline_stages
        args = {
          arn = self.input.pipeline_arn.value
        }
      }
    }
  }
}

query "aws_codepipeline_pipeline_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_codepipeline_pipeline
    order by
      arn;
  EOQ
}

query "aws_codepipeline_pipeline_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when encryption_key is null then 'Disabled' else 'Enabled' end as value,
      case when encryption_key is null then 'alert' else 'ok' end as type
    from
      aws_codepipeline_pipeline
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_codepipeline_pipeline_relationships_graph" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_codepipeline_pipeline' as category,
      jsonb_build_object(
        'ARN', arn,
        'Name', name,
        'Created At', created_at,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_codepipeline_pipeline
    where
      arn = $1

    -- From IAM roles (node)
    union all
     select
      null as from_id,
      null as to_id,
      role_id as id,
      name as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', arn,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id ) as properties
    from
      aws_iam_role
    where
      arn in
      (
        select
          role_arn
        from
          aws_codepipeline_pipeline
        where
          arn = $1
      )

    -- From IAM roles (edge)
    union all
     select
      p.arn as from_id,
      r.role_id as to_id,
      null as id,
      'iam role' as title,
      'codepipeline_pipeline_to_iam_role' as category,
      jsonb_build_object(
        'Account ID', p.account_id ) as properties
    from
      aws_iam_role as r,
      aws_codepipeline_pipeline as p
    where
      r.arn = p.role_arn
      and p.arn = $1

    -- From KMS keys (node)
    union all
     select
      null as from_id,
      null as to_id,
      id as id,
      title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', arn,
        'Key Manager', key_manager,
        'Creation Date', creation_date,
        'Enabled', enabled::text,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_kms_key,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasArn' in
      (
        select
          encryption_key ->> 'Id'
        from
          aws_codepipeline_pipeline
        where
          arn = $1
      )

    -- From KMS keys (edge)
    union all
     select
      p.arn as from_id,
      k.id as to_id,
      null as id,
      'encrypted' as title,
      'codepipeline_pipeline_to_kms_key' as category,
      jsonb_build_object(
        'Account ID', p.account_id ) as properties
    from
      aws_codepipeline_pipeline as p,
      aws_kms_key as k,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasArn' = p.encryption_key ->> 'Id'
      and p.arn = $1

    -- From CodeCommit repositories (node)
    union all
     select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_codecommit_repository' as category,
      jsonb_build_object(
        'ARN', arn,
        'Name', repository_name,
        'Creation Date', creation_date,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_codecommit_repository
    where
      repository_name in
      (
        select
          a -> 'Configuration' ->> 'RepositoryName'
        from
          aws_codepipeline_pipeline,
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Source'
          and a -> 'ActionTypeId' ->> 'Provider' = 'CodeCommit'
          and arn = $1
      )

     -- From CodeCommit repositories (edge)
    union all
     select
      r.arn as from_id,
      p.arn as to_id,
      null as id,
      'source' as title,
      'codecommit_repository_to_codepipeline_pipeline' as category,
      jsonb_build_object(
        'Account ID', p.account_id ) as properties
    from
      aws_codecommit_repository as r,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Source'
      and a -> 'ActionTypeId' ->> 'Provider' = 'CodeCommit'
      and a -> 'Configuration' ->> 'RepositoryName' = r.repository_name
      and p.arn = $1

     -- From ECR repositories (node)
    union all
     select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ecr_repository' as category,
      jsonb_build_object(
        'ARN', arn,
        'Name', repository_name,
        'Created At', created_at,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_ecr_repository
    where
      repository_name in
      (
        select
          a -> 'Configuration' ->> 'RepositoryName'
        from
          aws_codepipeline_pipeline,
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Source'
          and a -> 'ActionTypeId' ->> 'Provider' = 'ECR'
          and arn = $1
      )

     -- From ECR repositories (edge)
    union all
     select
      r.arn as from_id,
      p.arn as to_id,
      null as id,
      'source' as title,
      'ecr_repository_to_codepipeline_pipeline' as category,
      jsonb_build_object(
        'Account ID', p.account_id ) as properties
    from
      aws_ecr_repository as r,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Source'
      and a -> 'ActionTypeId' ->> 'Provider' = 'ECR'
      and a -> 'Configuration' ->> 'RepositoryName' = r.repository_name
      and p.arn = $1

    -- From S3 buckets -source (node)
    union all
     select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'ARN', arn,
        'Name', name,
        'Creation Date', creation_date,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_s3_bucket
    where
      name in
      (
        select
          a -> 'Configuration' ->> 'S3Bucket'
        from
          aws_codepipeline_pipeline,
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Source'
          and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
          and arn = $1
      )

    -- From S3 buckets - source (edge)
    union all
     select
      b.arn as from_id,
      p.arn as to_id,
      null as id,
      'source' as title,
      's3_bucket_to_codepipeline_pipeline' as category,
      jsonb_build_object(
        'Account ID', p.account_id ) as properties
    from
      aws_s3_bucket as b,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Source'
      and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
      and a -> 'Configuration' ->> 'S3Bucket' = b.name
      and p.arn = $1


    -- From CodeBuild projects (node)
    union all
     select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_codebuild_project' as category,
      jsonb_build_object(
        'ARN', arn,
        'Name', name,
        'Created', created,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_codebuild_project
    where
      name in
      (
        select
          a -> 'Configuration' ->> 'ProjectName'
        from
          aws_codepipeline_pipeline,
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Build'
          and a -> 'ActionTypeId' ->> 'Provider' = 'CodeBuild'
          and arn = $1
      )

    -- From CodeBuild projects (edge)
    union all
     select
      b.arn as from_id,
      p.arn as to_id,
      null as id,
      'build' as title,
      'codebuild_project_to_codepipeline_pipeline' as category,
      jsonb_build_object(
        'Account ID', p.account_id ) as properties
    from
      aws_codebuild_project as b,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Build'
      and a -> 'ActionTypeId' ->> 'Provider' = 'CodeBuild'
      and a -> 'Configuration' ->> 'ProjectName' = b.name
      and p.arn = $1

    -- From S3 buckets - deploy (node)
    union all
     select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'ARN', arn,
        'Name', name,
        'Creation Date', creation_date,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_s3_bucket
    where
      name in
      (
        select
          a -> 'Configuration' ->> 'BucketName'
        from
          aws_codepipeline_pipeline,
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Deploy'
          and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
          and arn = $1
      )

    -- From S3 buckets - deploy (edge)
    union all
     select
      p.arn as from_id,
      b.arn as to_id,
      null as id,
      'deploy' as title,
      'codepipeline_pipeline_to_s3_bucket' as category,
      jsonb_build_object(
        'Account ID', p.account_id ) as properties
    from
      aws_s3_bucket as b,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Deploy'
      and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
      and a -> 'Configuration' ->> 'BucketName' = b.name
      and p.arn = $1

    -- From CodeDeploy Applications (node)
    union all
     select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_codedeploy_app' as category,
      jsonb_build_object(
        'ARN', arn,
        'Name', application_name,
        'Create Time', create_time,
        'Compute Platform', compute_platform,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_codedeploy_app
    where
      application_name in
      (
        select
          a -> 'Configuration' ->> 'ApplicationName'
        from
          aws_codepipeline_pipeline,
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Deploy'
          and a -> 'ActionTypeId' ->> 'Provider' = 'CodeDeploy'
          and arn = $1
      )

    -- From CodeDeploy Applications (edge)
    union all
     select
      p.arn as from_id,
      app.arn as to_id,
      null as id,
      'deploy' as title,
      'codepipeline_pipeline_to_codedeploy_app' as category,
      jsonb_build_object(
        'Account ID', p.account_id ) as properties
    from
      aws_codedeploy_app as app,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Deploy'
      and a -> 'ActionTypeId' ->> 'Provider' = 'CodeDeploy'
      and a -> 'Configuration' ->> 'ApplicationName' = app.application_name
      and p.arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}

query "aws_codepipeline_pipeline_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      created_at as "Created At",
      updated_at as "Updated At",
      version as "Version",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_codepipeline_pipeline
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_codepipeline_pipeline_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_codepipeline_pipeline,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_codepipeline_pipeline_stages" {
  sql = <<-EOQ
    select
      s ->> 'Name' as "Name",
      a as "Actions"
    from
      aws_codepipeline_pipeline,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      arn = $1;
  EOQ

  param "arn" {}
}
