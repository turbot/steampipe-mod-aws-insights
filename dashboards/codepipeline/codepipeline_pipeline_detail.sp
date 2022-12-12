dashboard "codepipeline_pipeline_detail" {

  title         = "AWS CodePipeline Pipeline Detail"
  documentation = file("./dashboards/codepipeline/docs/codepipeline_pipeline_detail.md")

  tags = merge(local.codepipeline_common_tags, {
    type = "Detail"
  })

  input "pipeline_arn" {
    title = "Select a pipeline:"
    query = query.codepipeline_pipeline_input
    width = 4
  }

  container {

    card {
      query = query.codepipeline_pipeline_encryption
      width = 2
      args = {
        arn = self.input.pipeline_arn.value
      }
    }

  }

  # container {

  #   graph {
  #     title     = "Relationships"
  #     type      = "graph"
  #     direction = "TD"

  #     with "codebuild_projects" {
  #       sql = <<-EOQ
  #         select
  #           arn as codebuild_project_arn
  #         from
  #           aws_codebuild_project
  #         where
  #           name in
  #           (
  #             select
  #               a -> 'Configuration' ->> 'ProjectName'
  #             from
  #               aws_codepipeline_pipeline,
  #               jsonb_array_elements(stages) as s,
  #               jsonb_array_elements(s -> 'Actions') as a
  #             where
  #               s ->> 'Name' = 'Build'
  #               and a -> 'ActionTypeId' ->> 'Provider' = 'CodeBuild'
  #               and arn = $1
  #           );
  #       EOQ

  #       args = [self.input.pipeline_arn.value]
  #     }

  #     with "codecommit_repositories" {
  #       sql = <<-EOQ
  #         select
  #           arn as codecommit_repository_arn
  #         from
  #           aws_codecommit_repository
  #         where
  #           repository_name in
  #           (
  #             select
  #               a -> 'Configuration' ->> 'RepositoryName'
  #             from
  #               aws_codepipeline_pipeline,
  #               jsonb_array_elements(stages) as s,
  #               jsonb_array_elements(s -> 'Actions') as a
  #             where
  #               s ->> 'Name' = 'Source'
  #               and a -> 'ActionTypeId' ->> 'Provider' = 'CodeCommit'
  #               and arn = $1
  #           );
  #       EOQ

  #       args = [self.input.pipeline_arn.value]
  #     }

  #     with "ecr_repositories" {
  #       sql = <<-EOQ
  #         select
  #           arn as ecr_repository_arn
  #         from
  #           aws_ecr_repository
  #         where
  #           repository_name in
  #           (
  #             select
  #               a -> 'Configuration' ->> 'RepositoryName'
  #             from
  #               aws_codepipeline_pipeline,
  #               jsonb_array_elements(stages) as s,
  #               jsonb_array_elements(s -> 'Actions') as a
  #             where
  #               s ->> 'Name' = 'Source'
  #               and a -> 'ActionTypeId' ->> 'Provider' = 'ECR'
  #               and arn = $1
  #           );
  #       EOQ

  #       args = [self.input.pipeline_arn.value]
  #     }

  #     with "iam_roles" {
  #       sql = <<-EOQ
  #         select
  #           role_id as iam_role_id
  #         from
  #           aws_iam_role
  #         where
  #           arn in
  #           (
  #             select
  #               role_arn
  #             from
  #               aws_codepipeline_pipeline
  #             where
  #               arn = $1
  #           );
  #       EOQ

  #       args = [self.input.pipeline_arn.value]
  #     }

  #     with "kms_keys" {
  #       sql = <<-EOQ
  #         select
  #           encryption_key ->> 'Id' as kms_key_arn
  #         from
  #           aws_codepipeline_pipeline
  #         where
  #           encryption_key ->> 'Id' is not null
  #           and arn = $1
  #       EOQ

  #       args = [self.input.pipeline_arn.value]
  #     }

  #     with "s3_buckets" {
  #       sql = <<-EOQ
  #         select
  #           arn as s3_bucket_deploy_arn
  #         from
  #           aws_s3_bucket
  #         where
  #           name in
  #           (
  #             select
  #               a -> 'Configuration' ->> 'BucketName' as bucket_name
  #             from
  #               aws_codepipeline_pipeline,
  #               jsonb_array_elements(stages) as s,
  #               jsonb_array_elements(s -> 'Actions') as a
  #             where
  #               s ->> 'Name' = 'Deploy'
  #               and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
  #               and arn = $1
  #             union
  #             select
  #               a -> 'Configuration' ->> 'S3Bucket' as bucket_name
  #             from
  #               aws_codepipeline_pipeline,
  #               jsonb_array_elements(stages) as s,
  #               jsonb_array_elements(s -> 'Actions') as a
  #             where
  #               s ->> 'Name' = 'Source'
  #               and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
  #               and arn = $1
  #           );
  #       EOQ

  #       args = [self.input.pipeline_arn.value]
  #     }

  #     nodes = [
  #       node.codebuild_project,
  #       node.codecommit_repository,
  #       node.codedeploy_app,
  #       node.codepipeline_pipeline,
  #       node.ecr_repository,
  #       node.iam_role,
  #       node.kms_key,
  #       node.s3_bucket
  #     ]

  #     edges = [
  #       edge.codebuild_project_to_codepipeline_pipeline,
  #       edge.codecommit_repository_to_codepipeline_pipeline,
  #       edge.codedeploy_app_to_codepipeline_pipeline,
  #       edge.codepipeline_pipeline_to_s3_bucket,
  #       edge.ecr_repository_to_codepipeline_pipeline,
  #       edge.iam_role_to_codepipeline_pipeline,
  #       edge.kms_key_to_codepipeline_pipeline,
  #       edge.s3_bucket_to_codepipeline_pipeline
  #     ]

  #     args = {
  #       codebuild_project_arns     = with.codebuild_projects.rows[*].codebuild_project_arn
  #       codecommit_repository_arns = with.codecommit_repositories.rows[*].codecommit_repository_arn
  #       codepipeline_pipeline_arns = [self.input.pipeline_arn.value]
  #       ecr_repository_arns        = with.ecr_repositories.rows[*].ecr_repository_arn
  #       iam_role_arns              = with.iam_roles.rows[*].iam_role_id
  #       kms_key_arns               = with.kms_keys.rows[*].kms_key_arn
  #       s3_bucket_arns             = with.s3_buckets.rows[*].s3_bucket_deploy_arn
  #     }
  #   }
  # }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.codepipeline_pipeline_overview
        args = {
          arn = self.input.pipeline_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.codepipeline_pipeline_tags
        args = {
          arn = self.input.pipeline_arn.value
        }

      }
    }
    container {
      width = 6

      table {
        title = "Stages"
        query = query.codepipeline_pipeline_stages
        args = {
          arn = self.input.pipeline_arn.value
        }
      }
    }
  }
}

query "codepipeline_pipeline_input" {
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

query "codepipeline_pipeline_encryption" {
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

query "codepipeline_pipeline_overview" {
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

query "codepipeline_pipeline_tags" {
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

query "codepipeline_pipeline_stages" {
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
