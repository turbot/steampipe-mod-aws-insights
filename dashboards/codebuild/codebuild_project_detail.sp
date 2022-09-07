dashboard "aws_codebuild_project_detail" {

  title         = "AWS CodeBuild Project Detail"
  documentation = file("./dashboards/codebuild/docs/codebuild_project_detail.md")

  tags = merge(local.codebuild_common_tags, {
    type = "Detail"
  })

  input "codebuild_project_arn" {
    title = "Select a project:"
    query = query.aws_codebuild_project_input
    width = 4
  }
  
  container {

    card {
      width = 2
      query = query.aws_codebuild_project_encrypted
      args = {
        arn = self.input.codebuild_project_arn.value
      }
    }
    
    card {
      width = 2
      query = query.aws_codebuild_project_logging_enabled
      args = {
        arn = self.input.codebuild_project_arn.value
      }
    }
    
    card {
      width = 2
      query = query.aws_codebuild_project_privileged_mode
      args = {
        arn = self.input.codebuild_project_arn.value
      }
    }

  }
  
  container {

    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      title = "Relationships"
      query = query.aws_codebuild_project_relationships_graph
      args = {
        arn = self.input.codebuild_project_arn.value
      }

      category "aws_codebuild_project" {}
    }
  }
  
  container {
    width = 6

    table {
      title = "Overview"
      type  = "line"
      width = 6
      query = query.aws_codebuild_project_overview
      args = {
        arn = self.input.codebuild_project_arn.value
      }
    }

    table {
      title = "Tags"
      width = 6
      query = query.aws_codebuild_project_tags
      args = {
        arn = self.input.codebuild_project_arn.value
      }
    }
  }
  
  container {
    width = 6
    
    table {
      title = "Sources"
      query = query.aws_codebuild_project_sources
      args = {
        arn = self.input.codebuild_project_arn.value
      }
    }

  }

}

query "aws_codebuild_project_sources" {
  sql = <<-EOQ
    with sources as (
      select 
        source,
        secondary_sources
      from
        aws_codebuild_project
      where
        arn = $1
    )
    select
      source ->> 'Type' as "Type",
      source ->> 'Location' as "Location",
      source ->> 'GitCloneDepth' as "Clone Depth"
    from
      sources
    union all
    select
      s ->> 'Type' as "Type",
      s ->> 'Location' as "Location",
      s ->> 'GitCloneDepth' as "Clone Depth"
    from
      sources,
      jsonb_array_elements(secondary_sources) as s;
  EOQ
  
  param "arn" {}
}

query "aws_codebuild_project_encrypted" {
  sql = <<-EOQ
    select
      'Encrypted' as label,
      case when encryption_key is null then 'Disabled' else 'Enabled' end as value,
      case when encryption_key is null then 'alert' else 'ok' end as type
    from
      aws_codebuild_project
    where
      arn = $1;
  EOQ
  
  param "arn" {}
}

query "aws_codebuild_project_logging_enabled" {
  sql = <<-EOQ
    with enabled as (
      select
        case when logs_config -> 'CloudWatchLogs' ->> 'Status' = 'ENABLED' or logs_config -> 'S3Logs' ->> 'Status' = 'ENABLED' then true else false end as logging_value
      from
        aws_codebuild_project
      where
        arn = $1
    )
    select
      'Logging' as label,
      case when logging_value then 'Enabled' else 'Disabled' end as value,
      case when logging_value then 'ok' else 'alert' end as type
    from
      enabled
  EOQ
  
  param "arn" {}
}

query "aws_codebuild_project_privileged_mode" {
  sql = <<-EOQ
    select
      'Privileged Mode' as label,
      case when environment ->> 'PrivilegedMode' = 'true' then 'Enabled' else 'Disabled' end as value,
      case when environment ->> 'PrivilegedMode' = 'true' then 'alert' else 'ok' end as type
    from
      aws_codebuild_project
    where
      arn = $1;
  EOQ
  
  param "arn" {}
}

query "aws_codebuild_project_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      arn as "ARN",
      description as "Description",
      project_visibility as "Project Visibility",
      concurrent_build_limit as "Concurrent build limit"
    from
      aws_codebuild_project
    where
      arn = $1;
  EOQ
  
  param "arn" {}
}

query "aws_codebuild_project_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_codebuild_project,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_codebuild_project_relationships_graph" {
  sql = <<-EOQ
    with cbproject as (
      select
        arn,
        account_id,
        region,
        title,
        cache,
        encryption_key,
        artifacts,
        logs_config,
        environment,
        service_role,
        source
      from
        aws_codebuild_project
      where
        arn = $1
    )
    
    -- Resource (node)
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_codebuild_project' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'region', region
      ) as properties
    from 
      cbproject
      
    -- S3 bucket as cache (node)
    union all
    select
      null as from_id,
      null as to_id,
      'cache:'||s3.arn as id,
      s3.title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', s3.name,
        'ARN', s3.arn,
        'Account ID', s3.account_id,
        'Region', s3.region
      ) as properties
    from cbproject
    left join aws_s3_bucket as s3 on
      s3.name = split_part(cbproject.cache ->> 'Location', '/', 1)
      
    -- S3 bucket as cache (edge)
    union all
    select
      cbproject.arn as from_id,
      'cache:'||s3.arn as to_id,
      null as id,
      'caches in' as title,
      'codebuild_project_to_s3_bucket' as category,
      jsonb_build_object(
        'Name', s3.name,
        'ARN', s3.arn,
        'Account ID', s3.account_id,
        'Region', s3.region
      ) as properties
    from cbproject
    left join aws_s3_bucket as s3 on
      s3.name = split_part(cbproject.cache ->> 'Location', '/', 1)
      
    -- S3 bucket as artifacts (node)
    union all
    select
      null as from_id,
      null as to_id,
      'artifact:'||s3.arn as id,
      s3.title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', s3.name,
        'ARN', s3.arn,
        'Account ID', s3.account_id,
        'Region', s3.region
      ) as properties
    from cbproject
    left join aws_s3_bucket as s3 on
      s3.name = cbproject.artifacts ->> 'Location'
    where
      cbproject.artifacts->>'Type' = 'S3'
      
    -- S3 bucket as artifacts (node)
    union all
    select
      cbproject.arn as from_id,
      'artifact:'||s3.arn as to_id,
      null as id,
      'stores artifacts in' as title,
      'codebuild_project_to_s3_bucket' as category,
      jsonb_build_object(
        'Name', s3.name,
        'ARN', s3.arn,
        'Account ID', s3.account_id,
        'Region', s3.region
      ) as properties
    from cbproject
    left join aws_s3_bucket as s3 on
      s3.name = cbproject.artifacts ->> 'Location'
    where
      cbproject.artifacts->>'Type' = 'S3'
      
    -- S3 bucket as logsink (node)
    union all
    select
      null as from_id,
      null as to_id,
      'logconfig:'||s3.arn as id,
      s3.title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', s3.name,
        'ARN', s3.arn,
        'Account ID', s3.account_id,
        'Region', s3.region
      ) as properties
    from cbproject
    left join aws_s3_bucket as s3 on
      s3.name = split_part(cbproject.logs_config -> 'S3Logs' ->> 'Location', '/', 1)
      
    -- S3 bucket as logsink (edge)
    union all
    select
      cbproject.arn as from_id,
      'logconfig:'||s3.arn as to_id,
      null as id,
      'logs to' as title,
      'codebuild_project_to_s3_bucket' as category,
      jsonb_build_object(
        'Name', s3.name,
        'ARN', s3.arn,
        'Account ID', s3.account_id,
        'Region', s3.region
      ) as properties
    from cbproject
    left join aws_s3_bucket as s3 on
      s3.name = split_part(cbproject.logs_config -> 'S3Logs' ->> 'Location', '/', 1)
      
    -- S3 bucket as source (node)
    union all
    select
      null as from_id,
      null as to_id,
      'source:'||s3.arn as id,
      s3.title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', s3.name,
        'ARN', s3.arn,
        'Account ID', s3.account_id,
        'Region', s3.region
      ) as properties
    from cbproject
    left join aws_s3_bucket as s3 on
      s3.name = split_part(cbproject.source ->> 'Location', '/', 1)
    where cbproject.source ->> 'Type' = 'S3'
      
    -- S3 bucket as source (edge)
    union all
    select
      cbproject.arn as from_id,
      'source:'||s3.arn as to_id,
      null as id,
      'source' as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', s3.name,
        'ARN', s3.arn,
        'Account ID', s3.account_id,
        'Region', s3.region
      ) as properties
    from cbproject
    left join aws_s3_bucket as s3 on
      s3.name = split_part(cbproject.source ->> 'Location', '/', 1)
    where cbproject.source ->> 'Type' = 'S3'    
    
    -- To CloudWatch log group (node)
    union all
    select
      null as from_id,
      null as to_id,
      cloudwatch.arn as id,
      cloudwatch.title,
      'aws_cloudwatch_log_group' as category,
      jsonb_build_object(
        'ARN', cloudwatch.arn,
        'Account ID', cloudwatch.account_id,
        'Region', cloudwatch.region,
        'Retention days', cloudwatch.retention_in_days
      ) as properties
    from
      cbproject
      left join aws_cloudwatch_log_group cloudwatch on cloudwatch.name = logs_config -> 'CloudWatchLogs' ->> 'GroupName'

    -- To KMS keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      kms_key.arn as id,
      kms_key.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', kms_key.arn,
        'Key Manager',kms_key. key_manager,
        'Creation Date', kms_key.creation_date,
        'Enabled', kms_key.enabled::text,
        'Account ID', kms_key.account_id,
        'Region', kms_key.region 
      ) as properties
    from
      cbproject
      left join aws_kms_key as kms_key on kms_key.arn = cbproject.encryption_key

    -- To KMS keys (edge)
    union all
    select
      cbproject.arn as from_id,
      kms_key.arn as to_id,
      null as id,
      'encrypted with' as title,
      'codebuild_project_to_kms_key' as category,
      jsonb_build_object(
        'Account ID', kms_key.account_id
      ) as properties
    from
      cbproject
      left join aws_kms_key as kms_key on kms_key.arn = cbproject.encryption_key

    -- To IAM Service Role (node)
    union all
    select
      null as from_id,
      null as to_id,
      iam_role.arn as id,
      iam_role.title as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', iam_role.arn,
        'Path', iam_role.path,
        'Account ID', iam_role.account_id,
        'Region', iam_role.region 
      ) as properties
    from
      cbproject
      left join aws_iam_role as iam_role on iam_role.arn = cbproject.service_role

    -- To IAM Service Role (edge)
    union all
    select
      cbproject.arn as from_id,
      iam_role.arn as to_id,
      null as id,
      iam_role.title as title,
      'codebuild_project_to_iam_role' as category,
      jsonb_build_object(
        'Account ID', iam_role.account_id
      ) as properties
    from
      cbproject
      left join aws_iam_role as iam_role on iam_role.arn = cbproject.service_role

    -- To ECR repository (node)
    union all
    select
      null as from_id,
      null as to_id,
      repository.arn as id,
      repository.repository_name as title,
      'aws_ecr_repository' as category,
      jsonb_build_object(
        'ARN', repository.arn,
        'Created At', repository.created_at,
        'Repository URI', repository.repository_uri,
        'Account ID', repository.account_id,
        'Region', repository.region
      ) as properties
    from
      cbproject
      left join aws_ecr_repository as repository 
      on repository.repository_uri = split_part(cbproject.environment ->> 'Image', ':', 1)

    -- To ECR repository (edge)
    union all
    select
      cbproject.arn as from_id,
      repository.arn as to_id,
      null as id,
      'build environment' as title,
      'codebuild_project_to_ecr_repository' as category,
      jsonb_build_object(
        'Account ID', repository.account_id
      ) as properties
    from
      cbproject
      left join aws_ecr_repository as repository 
      on repository.repository_uri = split_part(cbproject.environment ->> 'Image', ':', 1)

    -- To CodeCommit repository (node)
    union all
    select
      null as from_id,
      null as to_id,
      repository.arn as id,
      repository.repository_name as title,
      'aws_codecommit_repository' as category,
      jsonb_build_object(
        'ARN', repository.arn,
        'Default Branch', repository.default_branch,
        'Repository Clone HTTP URL', repository.clone_url_http,
        'Repository Clone SSH URL', repository.clone_url_ssh,
        'Account ID', repository.account_id,
        'Region', repository.region
      ) as properties
    from
      cbproject
      left join aws_codecommit_repository as repository 
      on repository.clone_url_http in (
        with code_sources as (
          select 
            source,
            secondary_sources
          from
            aws_codebuild_project
          where
            arn = $1
        )
        select source ->> 'Location' as "Location" from code_sources
        union all
        select s ->> 'Location' as "Location" from code_sources, jsonb_array_elements(secondary_sources) as s
      )

    -- To CodeCommit repository (node)
    union all
    select
      cbproject.arn as from_id,
      repository.arn as to_id,
      null as id,
      repository.repository_name as title,
      'codebuild_project_to_codecommit_repository' as category,
      jsonb_build_object(
        'Account ID', repository.account_id
      ) as properties
    from
      cbproject
      left join aws_codecommit_repository as repository 
      on repository.clone_url_http in (
        with code_sources as (
          select 
            source,
            secondary_sources
          from
            aws_codebuild_project
          where
            arn = $1
        )
        select source ->> 'Location' as "Location" from code_sources
        union all
        select s ->> 'Location' as "Location" from code_sources, jsonb_array_elements(secondary_sources) as s
      )

    order by
      category,
      from_id,
      to_id;

  EOQ

  param "arn" {}

}

query "aws_codebuild_project_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'arn', arn
      ) as tags
    from
      aws_codebuild_project
    order by
      title;
  EOQ
}