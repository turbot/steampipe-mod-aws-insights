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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_codepipeline_pipeline_node,
        node.aws_codepipeline_pipeline_from_iam_role_node,
        node.aws_codepipeline_pipeline_from_kms_key_node,
        node.aws_codepipeline_pipeline_from_codecommit_repository_node,
        node.aws_codepipeline_pipeline_from_ecr_repository_node,
        node.aws_codepipeline_pipeline_from_s3_bucket_source_node,
        node.aws_codepipeline_pipeline_from_codebuild_project_node,
        node.aws_codepipeline_pipeline_from_s3_bucket_deploy_node,
        node.aws_codepipeline_pipeline_from_codedeploy_app_node
      ]

      edges = [
        edge.aws_codepipeline_pipeline_from_iam_role_edge,
        edge.aws_codepipeline_pipeline_from_kms_key_edge,
        edge.aws_codepipeline_pipeline_from_codecommit_repository_edge,
        edge.aws_codepipeline_pipeline_from_ecr_repository_edge,
        edge.aws_codepipeline_pipeline_from_s3_bucket_source_edge,
        edge.aws_codepipeline_pipeline_from_codebuild_project_edge,
        edge.aws_codepipeline_pipeline_from_s3_bucket_deploy_edge,
        edge.aws_codepipeline_pipeline_from_codedeploy_app_edge
      ]

      args = {
        arn = self.input.pipeline_arn.value
      }
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

category "aws_codepipeline_pipeline_no_link" {
  color = "blue"
}

node "aws_codepipeline_pipeline_node" {
  category = category.aws_codepipeline_pipeline_no_link

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Name', name,
        'Created At', created_at,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_codepipeline_pipeline
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codepipeline_pipeline_from_iam_role_node" {
  category = category.aws_iam_role

  sql = <<-EOQ
    select
      role_id as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ARN', arn,
        'Path', path,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id
      ) as properties
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
      );
  EOQ

  param "arn" {}
}

edge "aws_codepipeline_pipeline_from_iam_role_edge" {
  title = "iam role"

  sql = <<-EOQ
    select
      p.arn as from_id,
      r.role_id as to_id
    from
      aws_iam_role as r,
      aws_codepipeline_pipeline as p
    where
      r.arn = p.role_arn
      and p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codepipeline_pipeline_from_kms_key_node" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Key Manager', key_manager,
        'Creation Date', creation_date,
        'Enabled', enabled::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
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
      );
  EOQ

  param "arn" {}
}

edge "aws_codepipeline_pipeline_from_kms_key_edge" {
  title = "encrypted"

  sql = <<-EOQ
    select
      p.arn as from_id,
      k.id as to_id
    from
      aws_codepipeline_pipeline as p,
      aws_kms_key as k,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasArn' = p.encryption_key ->> 'Id'
      and p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codepipeline_pipeline_from_codecommit_repository_node" {
  category = category.aws_codecommit_repository

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Name', repository_name,
        'Creation Date', creation_date,
        'Account ID', account_id,
        'Region', region
      ) as properties
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
      );
  EOQ

  param "arn" {}
}

edge "aws_codepipeline_pipeline_from_codecommit_repository_edge" {
  title = "source"

  sql = <<-EOQ
    select
      r.arn as from_id,
      p.arn as to_id
    from
      aws_codecommit_repository as r,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Source'
      and a -> 'ActionTypeId' ->> 'Provider' = 'CodeCommit'
      and a -> 'Configuration' ->> 'RepositoryName' = r.repository_name
      and p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codepipeline_pipeline_from_ecr_repository_node" {
  category = category.aws_ecr_repository

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Name', repository_name,
        'Created At', created_at,
        'Account ID', account_id,
        'Region', region
      ) as properties
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
      );
  EOQ

  param "arn" {}
}

edge "aws_codepipeline_pipeline_from_ecr_repository_edge" {
  title = "source"

  sql = <<-EOQ
    select
      r.arn as from_id,
      p.arn as to_id
    from
      aws_ecr_repository as r,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Source'
      and a -> 'ActionTypeId' ->> 'Provider' = 'ECR'
      and a -> 'Configuration' ->> 'RepositoryName' = r.repository_name
      and p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codepipeline_pipeline_from_s3_bucket_source_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Name', name,
        'Creation Date', creation_date,
        'Account ID', account_id,
        'Region', region
      ) as properties
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
      );
  EOQ

  param "arn" {}
}

edge "aws_codepipeline_pipeline_from_s3_bucket_source_edge" {
  title = "source"

  sql = <<-EOQ
    select
      b.arn as from_id,
      p.arn as to_id
    from
      aws_s3_bucket as b,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Source'
      and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
      and a -> 'Configuration' ->> 'S3Bucket' = b.name
      and p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codepipeline_pipeline_from_codebuild_project_node" {
  category = category.aws_codebuild_project

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Name', name,
        'Created', created,
        'Account ID', account_id,
        'Region', region
      ) as properties
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
      );
  EOQ

  param "arn" {}
}

edge "aws_codepipeline_pipeline_from_codebuild_project_edge" {
  title = "build"

  sql = <<-EOQ
    select
      b.arn as from_id,
      p.arn as to_id
    from
      aws_codebuild_project as b,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Build'
      and a -> 'ActionTypeId' ->> 'Provider' = 'CodeBuild'
      and a -> 'Configuration' ->> 'ProjectName' = b.name
      and p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codepipeline_pipeline_from_s3_bucket_deploy_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Name', name,
        'Creation Date', creation_date,
        'Account ID', account_id,
        'Region', region
      ) as properties
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
      );
  EOQ

  param "arn" {}
}

edge "aws_codepipeline_pipeline_from_s3_bucket_deploy_edge" {
  title = "deploy"

  sql = <<-EOQ
   select
      p.arn as from_id,
      b.arn as to_id
    from
      aws_s3_bucket as b,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Deploy'
      and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
      and a -> 'Configuration' ->> 'BucketName' = b.name
      and p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codepipeline_pipeline_from_codedeploy_app_node" {
  category = category.aws_codedeploy_app

  sql = <<-EOQ
    select
      arn as id,
      title as title,
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
      );
  EOQ

  param "arn" {}
}

edge "aws_codepipeline_pipeline_from_codedeploy_app_edge" {
  title = "deploy"

  sql = <<-EOQ
   select
      p.arn as from_id,
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
      and p.arn = $1;
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
