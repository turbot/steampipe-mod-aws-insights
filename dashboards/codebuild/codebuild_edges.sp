edge "codebuild_project_to_artifact_s3_bucket" {
  title = "artifact"

  sql = <<-EOQ
    select
      p.arn as from_id,
      s3.arn as to_id
    from
      aws_codebuild_project as p,
      aws_s3_bucket as s3
    where
      p.arn = any($1)
      and s3.name = p.artifacts ->> 'Location';
  EOQ

  param "codebuild_project_arns" {}
}

edge "codebuild_project_to_cache_s3_bucket" {
  title = "cache"

  sql = <<-EOQ
    select
      p.arn as from_id,
      s3.arn as to_id
    from
      aws_codebuild_project as p,
      aws_s3_bucket as s3
    where
      p.arn = any($1)
      and s3.name = split_part(p.cache ->> 'Location', '/', 1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codebuild_project_to_cloudwatch_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      p.arn as from_id,
      c.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_cloudwatch_log_group c on c.name = logs_config -> 'CloudWatchLogs' ->> 'GroupName'
    where
      p.arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codebuild_project_to_codecommit_repository" {
  title = "codecommit repository"

  sql = <<-EOQ
    select
      p.arn as from_id,
      r.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_codecommit_repository as r on r.clone_url_http in (
        with code_sources as (
          select
            source,
            secondary_sources
          from
            aws_codebuild_project
          where
            arn = any($1)
        )
        select source ->> 'Location' as "Location" from code_sources
        union all
        select s ->> 'Location' as "Location" from code_sources, jsonb_array_elements(secondary_sources) as s
      )
    where
      p.arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codebuild_project_to_codepipeline_pipeline" {
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
      and p.arn = any($1);
  EOQ

  param "codepipeline_pipeline_arns" {}
}

edge "codebuild_project_to_ecr_repository" {
  title = "build environment"

  sql = <<-EOQ
    select
      p.arn as from_id,
      r.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_ecr_repository as r on r.repository_uri = split_part(p.environment ->> 'Image', ':', 1)
    where
      p.arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codebuild_project_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      arn as from_id,
      service_role as to_id
    from
      aws_codebuild_project
    where
      arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codebuild_project_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      encryption_key as to_id
    from
      aws_codebuild_project
    where
      arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codebuild_project_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    select
      p.arn as from_id,
      s3.arn as to_id
    from
      aws_codebuild_project as p,
      aws_s3_bucket as s3
    where
      p.arn = any($1)
      and  s3.name = split_part(p.logs_config -> 'S3Logs' ->> 'Location', '/', 1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codebuild_project_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    with sg_id as (
      select
        vpc_config -> 'SecurityGroupIds' as sg,
        arn
      from
        aws_codebuild_project
    )
    select
      c.arn as from_id,
      s.group_id as to_id
    from
      sg_id as c,
      aws_vpc_security_group as s
    where
      sg ?& array[s.group_id]
      and c.arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codebuild_project_vpc_security_group_to_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      trim((sg::text), '""') as from_id,
      s as to_id
    from
      aws_codebuild_project,
      jsonb_array_elements(vpc_config -> 'SecurityGroupIds') as sg,
      jsonb_array_elements(vpc_config -> 'Subnets') as s
    where
      arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}

edge "codebuild_project_vpc_security_group_subnet_to_vpc" {
  title = "vpc"

  sql = <<-EOQ
    select
      s as from_id,
      vpc_config-> 'VpcId' as to_id
    from
      aws_codebuild_project,
      jsonb_array_elements(vpc_config -> 'Subnets') as s
    where
      arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}