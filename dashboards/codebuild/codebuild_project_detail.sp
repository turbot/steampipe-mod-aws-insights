dashboard "codebuild_project_detail" {

  title         = "AWS CodeBuild Project Detail"
  documentation = file("./dashboards/codebuild/docs/codebuild_project_detail.md")

  tags = merge(local.codebuild_common_tags, {
    type = "Detail"
  })

  input "codebuild_project_arn" {
    title = "Select a project:"
    query = query.codebuild_project_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.codebuild_project_encrypted
      args  = [self.input.codebuild_project_arn.value]
    }

    card {
      width = 2
      query = query.codebuild_project_logging_enabled
      args  = [self.input.codebuild_project_arn.value]
    }

    card {
      width = 2
      query = query.codebuild_project_privileged_mode
      args  = [self.input.codebuild_project_arn.value]
    }

  }

  with "cloudwatch_groups" {
    query = query.codebuild_project_cloudwatch_groups
    args  = [self.input.codebuild_project_arn.value]
  }

  with "codecommit_repositories" {
    query = query.codebuild_project_codecommit_repositories
    args  = [self.input.codebuild_project_arn.value]
  }

  with "ecr_repositories" {
    query = query.codebuild_project_ecr_repositories
    args  = [self.input.codebuild_project_arn.value]
  }

  with "iam_roles" {
    query = query.codebuild_project_iam_roles
    args  = [self.input.codebuild_project_arn.value]
  }

  with "kms_keys" {
    query = query.codebuild_project_kms_keys
    args  = [self.input.codebuild_project_arn.value]
  }

  with "s3_buckets" {
    query = query.codebuild_project_s3_buckets
    args  = [self.input.codebuild_project_arn.value]
  }

  with "vpc_security_groups" {
    query = query.codebuild_project_vpc_security_groups
    args  = [self.input.codebuild_project_arn.value]
  }

  with "vpc_subnets" {
    query = query.codebuild_project_vpc_subnets
    args  = [self.input.codebuild_project_arn.value]
  }

  with "vpc_vpcs" {
    query = query.codebuild_project_vpc_vpcs
    args  = [self.input.codebuild_project_arn.value]
  }


  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.cloudwatch_log_group
        args = {
          cloudwatch_log_group_arns = with.cloudwatch_groups.rows[*].cloudwatch_log_group_arn
        }
      }

      node {
        base = node.codebuild_project
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      node {
        base = node.codecommit_repository
        args = {
          codecommit_repository_arns = with.codecommit_repositories.rows[*].codecommit_repository_arn
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
          s3_bucket_arns = with.s3_buckets.rows[*].s3_bucket_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups.rows[*].vpc_security_group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets.rows[*].vpc_subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs.rows[*].vpc_vpc_id
        }
      }

      edge {
        base = edge.codebuild_project_to_artifact_s3_bucket
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      edge {
        base = edge.codebuild_project_to_cache_s3_bucket
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      edge {
        base = edge.codebuild_project_to_cloudwatch_group
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      edge {
        base = edge.codebuild_project_to_ecr_repository
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      edge {
        base = edge.codebuild_project_to_iam_role
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      edge {
        base = edge.codebuild_project_to_kms_key
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      edge {
        base = edge.codebuild_project_to_s3_bucket
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      edge {
        base = edge.codebuild_project_to_vpc_security_group
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      edge {
        base = edge.codebuild_project_to_vpc_subnet
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      edge {
        base = edge.codecommit_repository_to_codebuild_project
        args = {
          codecommit_repository_arns = with.codecommit_repositories.rows[*].codecommit_repository_arn
        }
      }

      edge {
        base = edge.s3_bucket_to_codebuild_project
        args = {
          codebuild_project_arns = [self.input.codebuild_project_arn.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets.rows[*].vpc_subnet_id
        }
      }

    }
  }

  container {
    width = 6

    table {
      title = "Overview"
      type  = "line"
      width = 6
      query = query.codebuild_project_overview
      args  = [self.input.codebuild_project_arn.value]
    }

    table {
      title = "Tags"
      width = 6
      query = query.codebuild_project_tags
      args  = [self.input.codebuild_project_arn.value]
    }
  }

  container {
    width = 6

    table {
      title = "Sources"
      query = query.codebuild_project_sources
      args  = [self.input.codebuild_project_arn.value]
    }

  }

}

# Input queries

query "codebuild_project_input" {
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

# With queries

query "codebuild_project_cloudwatch_groups" {
  sql = <<-EOQ
    select
      c.arn as cloudwatch_log_group_arn
    from
      aws_codebuild_project as p
      left join aws_cloudwatch_log_group c
      on c.name = logs_config -> 'CloudWatchLogs' ->> 'GroupName'
    where
      c.arn is not null
      and p.arn = $1;
  EOQ
}

query "codebuild_project_codecommit_repositories" {
  sql = <<-EOQ
    select
      distinct r.arn as codecommit_repository_arn
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
      r.arn is not null
      and p.arn = $1;
  EOQ
}

query "codebuild_project_ecr_repositories" {
  sql = <<-EOQ
    select
      r.arn as ecr_repository_arn
    from
      aws_codebuild_project as p
      left join aws_ecr_repository as r on r.repository_uri = split_part(p.environment ->> 'Image', ':', 1)
    where
      r.arn is not null
      and p.arn = $1;
  EOQ
}

query "codebuild_project_iam_roles" {
  sql = <<-EOQ
    select
      service_role as iam_role_arn
    from
      aws_codebuild_project
    where
      arn = $1;
  EOQ
}

query "codebuild_project_kms_keys" {
  sql = <<-EOQ
    select
      encryption_key as kms_key_arn
    from
      aws_codebuild_project
    where
      arn = $1;
  EOQ
}

query "codebuild_project_s3_buckets" {
  sql = <<-EOQ
    select
      s3.arn as s3_bucket_arn
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
}

query "codebuild_project_vpc_security_groups" {
  sql = <<-EOQ
    with sg_id as (
    select
      vpc_config -> 'SecurityGroupIds' as sg,
      arn
    from
      aws_codebuild_project
  )
  select
    s.group_id as vpc_security_group_id
  from
    sg_id as c,
    aws_vpc_security_group as s
  where
    sg ?& array[s.group_id]
    and c.arn = $1;
  EOQ
}

query "codebuild_project_vpc_subnets" {
  sql = <<-EOQ
    select
      trim((s::text), '""') as vpc_subnet_id
    from
      aws_codebuild_project,
      jsonb_array_elements( vpc_config -> 'Subnets') as s
    where
      arn = $1
  EOQ
}

query "codebuild_project_vpc_vpcs" {
  sql = <<-EOQ
    select
      vpc_config ->> 'VpcId' as vpc_vpc_id
    from
      aws_codebuild_project
    where
      vpc_config ->> 'VpcId' is not null
      and arn = $1;
  EOQ
}

# Card queries

query "codebuild_project_encrypted" {
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
}

query "codebuild_project_logging_enabled" {
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
}

query "codebuild_project_privileged_mode" {
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
}

# Other detail page queries

query "codebuild_project_overview" {
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
}

query "codebuild_project_tags" {
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
}

query "codebuild_project_sources" {
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
}
