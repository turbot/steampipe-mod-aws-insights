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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_codebuild_project_node,
        node.aws_codebuild_project_to_s3_bucket_node,
        node.aws_codebuild_project_to_cloudwatch_group_node,
        node.aws_codebuild_project_to_kms_key_node,
        node.aws_codebuild_project_to_iam_role_node,
        node.aws_codebuild_project_to_ecr_repository_node,
        node.aws_codebuild_project_to_codecommit_repository_node
      ]

      edges = [
        edge.aws_codebuild_project_to_s3_bucket_edge,
        edge.aws_codebuild_project_to_cloudwatch_group_edge,
        edge.aws_codebuild_project_to_kms_key_edge,
        edge.aws_codebuild_project_to_iam_role_edge,
        edge.aws_codebuild_project_to_ecr_repository_edge,
        edge.aws_codebuild_project_to_codecommit_repository_edge
      ]

      args = {
        arn = self.input.codebuild_project_arn.value
      }
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

node "aws_codebuild_project_node" {
  category = category.aws_codebuild_project

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'region', region
      ) as properties
    from
      aws_codebuild_project
    where
      arn = $1
  EOQ

  param "arn" {}
}


node "aws_codebuild_project_to_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      s3.arn as id,
      s3.title as title,
      jsonb_build_object(
        'Name', s3.name,
        'ARN', s3.arn,
        'Account ID', s3.account_id,
        'Region', s3.region
      ) as properties
    from
      aws_codebuild_project as p,
      aws_s3_bucket as s3
    where
      p.arn = $1
      and (s3.name = split_part(p.cache ->> 'Location', '/', 1)
           or s3.name = p.artifacts ->> 'Location'
           or s3.name = split_part(p.logs_config -> 'S3Logs' ->> 'Location', '/', 1)
           or s3.name = split_part(p.source ->> 'Location', '/', 1)
          )
  EOQ

  param "arn" {}
}

edge "aws_codebuild_project_to_s3_bucket_edge" {
  title = "s3 bucket"

  sql = <<-EOQ
    select
      p.arn as from_id,
      s3.arn as to_id
    from
      aws_codebuild_project as p,
      aws_s3_bucket as s3
    where
      p.arn = $1
      and (s3.name = split_part(p.cache ->> 'Location', '/', 1)
           or s3.name = p.artifacts ->> 'Location'
           or s3.name = split_part(p.logs_config -> 'S3Logs' ->> 'Location', '/', 1)
           or s3.name = split_part(p.source ->> 'Location', '/', 1)
          );
  EOQ

  param "arn" {}
}

node "aws_codebuild_project_to_cloudwatch_group_node" {
  category = category.aws_cloudwatch_log_group

  sql = <<-EOQ
    select
      cloudwatch.arn as id,
      cloudwatch.title as title,
      jsonb_build_object(
        'ARN', cloudwatch.arn,
        'Account ID', cloudwatch.account_id,
        'Region', cloudwatch.region,
        'Retention days', cloudwatch.retention_in_days
      ) as properties
    from
      aws_codebuild_project as p
      left join aws_cloudwatch_log_group cloudwatch
      on cloudwatch.name = logs_config -> 'CloudWatchLogs' ->> 'GroupName'
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_codebuild_project_to_cloudwatch_group_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      p.arn as from_id,
      cloudwatch.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_cloudwatch_log_group cloudwatch on
      cloudwatch.name = logs_config -> 'CloudWatchLogs' ->> 'GroupName'
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codebuild_project_to_kms_key_node" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      kms_key.arn as id,
      kms_key.title as title,
      jsonb_build_object(
        'ARN', kms_key.arn,
        'Key Manager',kms_key. key_manager,
        'Creation Date', kms_key.creation_date,
        'Enabled', kms_key.enabled::text,
        'Account ID', kms_key.account_id,
        'Region', kms_key.region
      ) as properties
    from
      aws_codebuild_project as p
      left join aws_kms_key as kms_key
      on kms_key.arn = encryption_key
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_codebuild_project_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      p.arn as from_id,
      kms_key.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_kms_key as kms_key
      on kms_key.arn = p.encryption_key
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codebuild_project_to_iam_role_node" {
  category = category.aws_iam_role

  sql = <<-EOQ
    select
      iam_role.arn as id,
      iam_role.title as title,
      jsonb_build_object(
        'ARN', iam_role.arn,
        'Path', iam_role.path,
        'Account ID', iam_role.account_id,
        'Region', iam_role.region
      ) as properties
    from
      aws_codebuild_project as p
      left join aws_iam_role as iam_role
      on iam_role.arn = p.service_role
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_codebuild_project_to_iam_role_edge" {
  title = "assumes"

  sql = <<-EOQ
    select
      p.arn as from_id,
      iam_role.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_iam_role as iam_role
      on iam_role.arn = p.service_role
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codebuild_project_to_ecr_repository_node" {
  category = category.aws_ecr_repository

  sql = <<-EOQ
    select
      repository.arn as id,
      repository.repository_name as title,
      jsonb_build_object(
        'ARN', repository.arn,
        'Created At', repository.created_at,
        'Repository URI', repository.repository_uri,
        'Account ID', repository.account_id,
        'Region', repository.region
      ) as properties
    from
      aws_codebuild_project as p
      left join aws_ecr_repository as repository
      on repository.repository_uri = split_part(p.environment ->> 'Image', ':', 1)
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_codebuild_project_to_ecr_repository_edge" {
  title = "build environment"

  sql = <<-EOQ
    select
      p.arn as from_id,
      repository.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_ecr_repository as repository
      on repository.repository_uri = split_part(p.environment ->> 'Image', ':', 1)
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codebuild_project_to_codecommit_repository_node" {
  category = category.aws_codecommit_repository

  sql = <<-EOQ
    select
      repository.arn as id,
      repository.repository_name as title,
      jsonb_build_object(
        'ARN', repository.arn,
        'Default Branch', repository.default_branch,
        'Repository Clone HTTP URL', repository.clone_url_http,
        'Repository Clone SSH URL', repository.clone_url_ssh,
        'Account ID', repository.account_id,
        'Region', repository.region
      ) as properties
    from
      aws_codebuild_project as p
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
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_codebuild_project_to_codecommit_repository_edge" {
  title = "codecommit repository"

  sql = <<-EOQ
    select
      p.arn as from_id,
      repository.arn as to_id
    from
      aws_codebuild_project as p
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
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}
