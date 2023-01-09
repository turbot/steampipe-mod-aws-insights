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
      args  = [self.input.pipeline_arn.value]
    }

  }
  with "codebuild_projects" {
    query = query.codepipeline_pipeline_codebuild_projects
    args  = [self.input.pipeline_arn.value]
  }

  with "codecommit_repositories" {
    query = query.codepipeline_pipeline_codecommit_repositories
    args  = [self.input.pipeline_arn.value]
  }

  with "ecr_repositories" {
    query = query.codepipeline_pipeline_ecr_repositories
    args  = [self.input.pipeline_arn.value]
  }

  with "iam_roles" {
    query = query.codepipeline_pipeline_iam_roles
    args  = [self.input.pipeline_arn.value]
  }

  with "kms_keys" {
    query = query.codepipeline_pipeline_kms_keys
    args  = [self.input.pipeline_arn.value]
  }

  with "s3_buckets" {
    query = query.codepipeline_pipeline_s3_buckets
    args  = [self.input.pipeline_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      base      = graph.codepipeline_pipeline_structures
      type      = "graph"
      direction = "TD"
      args = {
        codepipeline_pipeline_arns = [self.input.pipeline_arn.value]
      }

      node {
        base = node.codebuild_project
        args = {
          codebuild_project_arns = with.codebuild_projects.rows[*].codebuild_project_arn
        }
      }

      node {
        base = node.codecommit_repository
        args = {
          codecommit_repository_arns = with.codecommit_repositories.rows[*].codecommit_repository_arn
        }
      }

      node {
        base = node.codedeploy_app
        args = {
          codepipeline_pipeline_arns = [self.input.pipeline_arn.value]
        }
      }

      node {
        base = node.codepipeline_pipeline
        args = {
          codepipeline_pipeline_arns = [self.input.pipeline_arn.value]
        }
      }

      node {
        base = node.ecr_repository
        args = {
          ecr_repository_arns = with.ecr_repositories.rows[*].ecr_repository_arn
        }
      }

      node {
        base = node.iam_role
        args = {
          iam_role_arns = with.iam_roles.rows[*].iam_role_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys.rows[*].kms_key_arn
        }
      }

      node {
        base = node.s3_bucket
        args = {
          s3_bucket_arns = with.s3_buckets.rows[*].s3_bucket_deploy_arn
        }
      }

      edge {
        base = edge.codepipeline_pipeline_build_to_codebuild_project
        args = {
          codebuild_project_arns = with.codebuild_projects.rows[*].codebuild_project_arn
        }
      }

      edge {
        base = edge.codepipeline_pipeline_source_to_codecommit_repository
        args = {
          codecommit_repository_arns = with.codecommit_repositories.rows[*].codecommit_repository_arn
        }
      }

      edge {
        base = edge.codepipeline_pipeline_deploy_to_codedeploy_app
        args = {
          codepipeline_pipeline_arns = [self.input.pipeline_arn.value]
        }
      }

      edge {
        base = edge.codepipeline_pipeline_deploy_to_s3_bucket
        args = {
          codepipeline_pipeline_arns = [self.input.pipeline_arn.value]
        }
      }

      edge {
        base = edge.codepipeline_pipeline_source_to_ecr_repository
        args = {
          ecr_repository_arns = with.ecr_repositories.rows[*].ecr_repository_arn
        }
      }

      edge {
        base = edge.codepipeline_pipeline_to_iam_role
        args = {
          codepipeline_pipeline_arns = [self.input.pipeline_arn.value]
        }
      }

      edge {
        base = edge.codepipeline_pipeline_to_kms_key
        args = {
          codepipeline_pipeline_arns = [self.input.pipeline_arn.value]
        }
      }

      edge {
        base = edge.codepipeline_pipeline_source_to_s3_bucket
        args = {
          codepipeline_pipeline_arns = [self.input.pipeline_arn.value]
        }
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
        query = query.codepipeline_pipeline_overview
        args  = [self.input.pipeline_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.codepipeline_pipeline_tags
        args  = [self.input.pipeline_arn.value]

      }
    }
    container {
      width = 6

      table {
        title = "Stages"
        query = query.codepipeline_pipeline_stages
        args  = [self.input.pipeline_arn.value]
      }
    }
  }
}

# Input queries

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

# With queries

query "codepipeline_pipeline_codebuild_projects" {
  sql = <<-EOQ
    select
      arn as codebuild_project_arn
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
}

query "codepipeline_pipeline_codecommit_repositories" {
  sql = <<-EOQ
    select
      arn as codecommit_repository_arn
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
}

query "codepipeline_pipeline_ecr_repositories" {
  sql = <<-EOQ
    select
      arn as ecr_repository_arn
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
}

query "codepipeline_pipeline_iam_roles" {
  sql = <<-EOQ
    select
      arn as iam_role_arn
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
}

query "codepipeline_pipeline_kms_keys" {
  sql = <<-EOQ
    select
      k.arn as kms_key_arn
    from
      aws_codepipeline_pipeline as p,
      aws_kms_key as k,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasArn' = p.encryption_key ->> 'Id'
      and p.arn = $1;
  EOQ
}

query "codepipeline_pipeline_s3_buckets" {
  sql = <<-EOQ
    select
      arn as s3_bucket_deploy_arn
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
          and arn = $1
        union
        select
          a -> 'Configuration' ->> 'S3Bucket' as bucket_name
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
}

# Card queries

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
}

# Other detail page queries

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
}
