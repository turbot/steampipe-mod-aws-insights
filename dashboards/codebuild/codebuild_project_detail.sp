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
        node.codebuild_project_node,
        node.codebuild_project_to_s3_bucket_node,
        node.codebuild_project_to_cloudwatch_group_node,
        node.codebuild_project_to_kms_key_node,
        node.codebuild_project_to_iam_role_node,
        node.codebuild_project_to_ecr_repository_node,
        node.codebuild_project_to_codecommit_repository_node,
        node.codebuild_project_to_vpc_security_group_node,
        node.codebuild_project_vpc_security_group_to_subnet_node,
        node.codebuild_project_vpc_security_group_subnet_to_vpc_node
      ]

      edges = [
        edge.codebuild_project_to_s3_bucket_edge,
        edge.codebuild_project_to_artifact_s3_bucket_edge,
        edge.codebuild_project_to_cache_s3_bucket_edge,
        edge.codebuild_project_from_s3_bucket_edge,
        edge.codebuild_project_to_cloudwatch_group_edge,
        edge.codebuild_project_to_kms_key_edge,
        edge.codebuild_project_to_iam_role_edge,
        edge.codebuild_project_to_ecr_repository_edge,
        edge.codebuild_project_to_codecommit_repository_edge,
        edge.codebuild_project_to_vpc_security_group_edge,
        edge.codebuild_project_vpc_security_group_to_subnet_edge,
        edge.codebuild_project_vpc_security_group_subnet_to_vpc_edge
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
      'Encryption' as label,
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
      description as "Description",
      project_visibility as "Project Visibility",
      concurrent_build_limit as "Concurrent build limit",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
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

node "codebuild_project_node" {
  category = category.codebuild_project

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ARN', arn,
        'Project Visibility', project_visibility,
        'Account ID', account_id,
        'region', region
      ) as properties
    from
      aws_codebuild_project
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "codebuild_project_to_s3_bucket_node" {
  category = category.s3_bucket

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
      );
  EOQ

  param "arn" {}
}

edge "codebuild_project_to_s3_bucket_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      p.arn as from_id,
      s3.arn as to_id
    from
      aws_codebuild_project as p,
      aws_s3_bucket as s3
    where
      p.arn = $1
      and  s3.name = split_part(p.logs_config -> 'S3Logs' ->> 'Location', '/', 1);
  EOQ

  param "arn" {}
}

edge "codebuild_project_to_artifact_s3_bucket_edge" {
  title = "artifact"

  sql = <<-EOQ
    select
      p.arn as from_id,
      s3.arn as to_id
    from
      aws_codebuild_project as p,
      aws_s3_bucket as s3
    where
      p.arn = $1
      and s3.name = p.artifacts ->> 'Location';
  EOQ

  param "arn" {}
}

edge "codebuild_project_to_cache_s3_bucket_edge" {
  title = "cache"

  sql = <<-EOQ
    select
      p.arn as from_id,
      s3.arn as to_id
    from
      aws_codebuild_project as p,
      aws_s3_bucket as s3
    where
      p.arn = $1
      and s3.name = split_part(p.cache ->> 'Location', '/', 1);
  EOQ

  param "arn" {}
}

edge "codebuild_project_from_s3_bucket_edge" {
  title = "source provider"

  sql = <<-EOQ
    select
      s3.arn as from_id,
      p.arn as to_id
    from
      aws_codebuild_project as p,
      aws_s3_bucket as s3
    where
      p.arn = $1
      and s3.name = split_part(p.source ->> 'Location', '/', 1);
  EOQ

  param "arn" {}
}

node "codebuild_project_to_cloudwatch_group_node" {
  category = category.cloudwatch_log_group

  sql = <<-EOQ
    select
      c.arn as id,
      c.title as title,
      jsonb_build_object(
        'ARN', c.arn,
        'Account ID', c.account_id,
        'Region', c.region,
        'Retention days', c.retention_in_days
      ) as properties
    from
      aws_codebuild_project as p
      left join aws_cloudwatch_log_group c
      on c.name = logs_config -> 'CloudWatchLogs' ->> 'GroupName'
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

edge "codebuild_project_to_cloudwatch_group_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      p.arn as from_id,
      c.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_cloudwatch_log_group c on c.name = logs_config -> 'CloudWatchLogs' ->> 'GroupName'
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

node "codebuild_project_to_kms_key_node" {
  category = category.kms_key

  sql = <<-EOQ
    select
      k.arn as id,
      k.title as title,
      jsonb_build_object(
        'ARN', k.arn,
        'Key Manager',k. key_manager,
        'Creation Date', k.creation_date,
        'Enabled', k.enabled::text,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_codebuild_project as p
      left join aws_kms_key as k
      on k.arn = encryption_key
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

edge "codebuild_project_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      p.arn as from_id,
      k.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_kms_key as k
      on k.arn = p.encryption_key
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

node "codebuild_project_to_iam_role_node" {
  category = category.iam_role

  sql = <<-EOQ
    select
      r.arn as id,
      r.title as title,
      jsonb_build_object(
        'ARN', r.arn,
        'Path', r.path,
        'Account ID', r.account_id,
        'Region', r.region
      ) as properties
    from
      aws_codebuild_project as p
      left join aws_iam_role as r on r.arn = p.service_role
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

edge "codebuild_project_to_iam_role_edge" {
  title = "assumes"

  sql = <<-EOQ
    select
      p.arn as from_id,
      r.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_iam_role as r on r.arn = p.service_role
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

node "codebuild_project_to_ecr_repository_node" {
  category = category.ecr_repository

  sql = <<-EOQ
    select
      r.arn as id,
      r.title as title,
      jsonb_build_object(
        'ARN', r.arn,
        'Created At', r.created_at,
        'Repository URI', r.repository_uri,
        'Account ID', r.account_id,
        'Region', r.region
      ) as properties
    from
      aws_codebuild_project as p
      left join aws_ecr_repository as r on r.repository_uri = split_part(p.environment ->> 'Image', ':', 1)
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

edge "codebuild_project_to_ecr_repository_edge" {
  title = "build environment"

  sql = <<-EOQ
    select
      p.arn as from_id,
      r.arn as to_id
    from
      aws_codebuild_project as p
      left join aws_ecr_repository as r on r.repository_uri = split_part(p.environment ->> 'Image', ':', 1)
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

node "codebuild_project_to_codecommit_repository_node" {
  category = category.codecommit_repository

  sql = <<-EOQ
    select
      r.arn as id,
      r.title as title,
      jsonb_build_object(
        'ARN', r.arn,
        'Default Branch', r.default_branch,
        'Repository Clone HTTP URL', r.clone_url_http,
        'Repository Clone SSH URL', r.clone_url_ssh,
        'Account ID', r.account_id,
        'Region', r.region
      ) as properties
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

edge "codebuild_project_to_codecommit_repository_edge" {
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

node "codebuild_project_to_vpc_security_group_node" {
  category = category.vpc_security_group

  sql = <<-EOQ
    with sg_id as (
      select
        vpc_config -> 'SecurityGroupIds' as sg,
        arn
      from
        aws_codebuild_project
    )
    select
      s.group_id as id,
      s.title as title,
      jsonb_build_object(
        'ARN', s.arn,
        'Group Name', s.group_name,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      sg_id as c,
      aws_vpc_security_group as s
    where
      sg ?& array[s.group_id]
      and c.arn = $1;
  EOQ

  param "arn" {}
}

edge "codebuild_project_to_vpc_security_group_edge" {
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
      and c.arn = $1;
  EOQ

  param "arn" {}
}

node "codebuild_project_vpc_security_group_to_subnet_node" {
  category = category.vpc_subnet

  sql = <<-EOQ
    with sn_id as (
      select
        trim((s::text), '""') as subnet_id
      from
        aws_codebuild_project,
        jsonb_array_elements( vpc_config -> 'Subnets') as s
      where
        arn = $1
    )
    select
      s.subnet_id as id,
      s.title as title,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'CIDR Block', s.cidr_block,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      sn_id as c
      left join aws_vpc_subnet as s on c.subnet_id = s.subnet_id
  EOQ

  param "arn" {}
}

edge "codebuild_project_vpc_security_group_to_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    with subnet_list as (
      select
        trim((s::text), '""') as subnet_id
      from
        aws_codebuild_project,
        jsonb_array_elements(vpc_config -> 'Subnets') as s
      where
        arn = $1
    ),
    sg_list as (
      select
        trim((s::text), '""') as sg_id
      from
        aws_codebuild_project,
        jsonb_array_elements(vpc_config -> 'SecurityGroupIds') as s
      where
        arn = $1
    )
    select
      sgl.sg_id as from_id,
      sl.subnet_id as to_id
    from
      subnet_list as sl,
      sg_list as sgl
  EOQ

  param "arn" {}
}

node "codebuild_project_vpc_security_group_subnet_to_vpc_node" {
  category = category.vpc_vpc

  sql = <<-EOQ
    with vpc_list as (
      select
        vpc_config ->>'VpcId' as v_id
      from
        aws_codebuild_project
      where
        arn = $1
    )
    select
      vp.vpc_id as id,
      vp.title as title,
      jsonb_build_object(
        'ARN', vp.arn,
        'CIDR Block', vp.cidr_block,
        'Account ID', vp.account_id,
        'Region', vp.region
      ) as properties
    from
      vpc_list as v
      left join aws_vpc as vp on v.v_id = vp.vpc_id
  EOQ

  param "arn" {}
}

edge "codebuild_project_vpc_security_group_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    with vpc_list as (
      select
        vpc_config ->>'VpcId' as v_id
      from
        aws_codebuild_project
       where
        arn = $1
    ),
    subnet_list as (
      select
        trim((s::text), '""') as subnet_id
      from
        aws_codebuild_project,
        jsonb_array_elements(vpc_config -> 'Subnets') as s
    )
    select
      sl.subnet_id as from_id,
      vpcl.v_id as to_id
    from
      subnet_list as sl,
      vpc_list as vpcl
  EOQ

  param "arn" {}
}
