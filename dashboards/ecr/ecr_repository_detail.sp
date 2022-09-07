dashboard "aws_ecr_repository_detail" {

  title         = "AWS ECR Repository Detail"
  documentation = file("./dashboards/ecr/docs/ecr_repository_detail.md")

  tags = merge(local.ecr_common_tags, {
    type = "Detail"
  })

  input "ecr_repository_arn" {
    title = "Select a Repository:"
    query = query.aws_ecr_repository_input
    width = 4
  }

  container {

    card {
      query = query.aws_ecr_repository_encrypted
      width = 2
      args = {
        arn = self.input.ecr_repository_arn.value
      }
    }

    card {
      query = query.aws_ecr_repository_scan_on_push
      width = 2
      args = {
        arn = self.input.ecr_repository_arn.value
      }
    }

    card {
      query = query.aws_ecr_repository_tagging
      width = 2
      args = {
        arn = self.input.ecr_repository_arn.value
      }
    }

    card {
      query = query.aws_ecr_repository_tag_immutability
      width = 2
      args = {
        arn = self.input.ecr_repository_arn.value
      }
    }

  }

  container {
    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_ecr_repository_relationships_graph
      args = {
        arn = self.input.ecr_repository_arn.value
      }
      category "aws_ecr_repository" {
        icon = local.aws_ecr_repository_icon
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
        query = query.aws_ecr_repository_overview
        args = {
          arn = self.input.ecr_repository_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_ecr_repository_tags
        args = {
          arn = self.input.ecr_repository_arn.value
        }
      }
    }
  }
}

query "aws_ecr_repository_encrypted" {
  sql = <<-EOQ
    select
      'Encrypted' as label,
      case when encryption_configuration is not null then 'Enabled' else 'Disabled' end as value,
      case when encryption_configuration is not null then 'ok' else 'alert' end as type
    from
      aws_ecr_repository
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecr_repository_tagging" {
  sql = <<-EOQ
    with num_tags as (
      select
        cardinality(array(select jsonb_object_keys(tags))) as num_tag_keys
      from
        aws_ecr_repository
      where
        arn = $1
    )
    select
      'Tags' as label,
      num_tag_keys value,
      case when num_tag_keys > 0 then 'ok' else 'alert' end as type
    from
      num_tags;
  EOQ

  param "arn" {}
}

query "aws_ecr_repository_public_access" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      initcap(image_tag_mutability) as value,
      case when image_tag_mutability = 'IMMUTABLE' then 'ok' else 'alert' end as type
    from
      aws_ecr_repository
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecr_repository_tag_immutability" {
  sql = <<-EOQ
    select
      'Tag Immutability' as label,
      initcap(image_tag_mutability) as value,
      case when image_tag_mutability = 'IMMUTABLE' then 'ok' else 'alert' end as type
    from
      aws_ecr_repository
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecr_repository_scan_on_push" {
  sql = <<-EOQ
    with scan_on_push as (
      select
        (image_scanning_configuration ->> 'ScanOnPush')::bool as scan
      from
        aws_ecr_repository
      where
        arn = $1
    )
    select
      'Scan on Push' as label,
      case when scan then 'Enabled' else 'Disabled' end as value,
      case when scan then 'ok' else 'alert' end as type
    from
      scan_on_push;
  EOQ

  param "arn" {}
}

query "aws_ecr_repository_relationships_graph" {
  sql = <<-EOQ
    with repository as (
      select
        arn,
        registry_id,
        repository_name,
        repository_uri,
        image_details,
        encryption_configuration,
        title,
        account_id,
        region
      from
        aws_ecr_repository
      where
        arn = $1
    )
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ecr_repository' as category,
      jsonb_build_object(
        'ARN', arn,
        'Image Details', image_details,
        'Account ID', account_id,
        'Region', region 
      ) as properties
    from
      repository

    -- To ECR Image (node)
    union all
    select
      null as from_id,
      null as to_id,
      ecr_images.image_digest as id,
      ecr_images.repository_name as title,
      'aws_ecr_image' as category,
      jsonb_build_object(
        'Manifest Media Type', ecr_images.image_manifest_media_type,
        'Artifact Media Type', ecr_images.artifact_media_type,
        'Image Digest', ecr_images.image_digest,
        'Image Size (in Bytes)', ecr_images.image_size_in_bytes,
        'Tags', ecr_images.image_tags,
        'Pushed at', ecr_images.image_pushed_at,
        'Account ID', ecr_images.account_id,
        'Region', ecr_images.region
      ) as properties
    from 
      repository
    left join aws_ecr_image ecr_images
    on 
      ecr_images.registry_id = repository.registry_id
      and ecr_images.repository_name = repository.repository_name

    -- To ECR Image (edge)
    union all
    select
      repository.arn as from_id,
      ecr_images.image_digest as to_id,
      null as id,
      'image' as title,
      'ecs_repository_to_ecr_image' as category,
      jsonb_build_object(
        'Account ID', ecr_images.account_id
      ) as properties
    from 
      repository
    left join aws_ecr_image ecr_images
    on 
      ecr_images.registry_id = repository.registry_id
      and ecr_images.repository_name = repository.repository_name
      
    -- To ECS Task Definition (node)
    union all
    select
      null as from_id,
      null as to_id,
      def.task_definition_arn as id,
      def.title as title,
      'aws_ecs_task_definition' as category,
      jsonb_build_object(
        'ARN', def.task_definition_arn,
        'Status', def.status,
        'Image', d ->> 'Image',
        'Account ID', def.account_id,
        'Region', def.region
      ) as properties
    from 
      repository,
      aws_ecs_task_definition as def,
      jsonb_array_elements(container_definitions) as d
    where
      repository.repository_uri = split_part(d ->> 'Image', ':', 1)
      
    -- To ECS Task Definition (edge)
    union all
    select
      repository.arn as from_id,
      def.task_definition_arn as to_id,
      null as id,
      'defined with' as title,
      'ecr_repository_to_ecs_service_to' as category,
      jsonb_build_object(
        'Account ID', def.account_id
      ) as properties
    from 
      repository,
      aws_ecs_task_definition as def,
      jsonb_array_elements(container_definitions) as d
    where
      repository.repository_uri = split_part(d ->> 'Image', ':', 1)

    -- To KMS keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      kms_keys.arn as id,
      kms_keys.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', kms_keys.arn,
        'Account ID', kms_keys.account_id,
        'Region', kms_keys.region,
        'Key Manager', kms_keys.key_manager
      ) as properties
    from
      repository
      left join aws_kms_key as kms_keys 
        on kms_keys.arn = repository.encryption_configuration ->> 'KmsKey'

    -- To KMS keys (edge)
    union all
    select
      repository.arn as from_id,
      kms_keys.arn as to_id,
      null as id,
      'KMS Key' as title,
      'ecr_repository_to_kms_key' as category,
      jsonb_build_object(
        'Account ID', kms_keys.account_id
      ) as properties
    from
      repository
      left join aws_kms_key as kms_keys 
        on kms_keys.arn = repository.encryption_configuration ->> 'KmsKey'

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}

query "aws_ecr_repository_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      registry_id as "Registry ID",
      repository_uri as "Repository URI",
      created_at as "Created at",
      ---
--      encryption_configuration,
--      image_details,
--      image_scanning_configuration,
--      image_scanning_findings,
--      image_tag_mutability,
--      lifecycle_policy,
--      policy_std,
      ---
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_ecr_repository
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ecr_repository_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ecr_repository,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_ecr_repository_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_ecr_repository
    order by
      title;
  EOQ
}