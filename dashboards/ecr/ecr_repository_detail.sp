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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_ecr_repository_node,
        node.aws_ecr_repository_to_ecr_image_node,
        node.aws_ecr_repository_to_ecs_task_definition_node,
        node.aws_ecr_repository_to_kms_key_node
      ]

      edges = [
        edge.aws_ecr_repository_to_ecr_image_edge,
        edge.aws_ecr_repository_to_ecs_task_definition_edge,
        edge.aws_ecr_repository_to_kms_key_edge
      ]

      args = {
        arn = self.input.ecr_repository_arn.value
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

query "aws_ecr_repository_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      registry_id as "Registry ID",
      repository_uri as "Repository URI",
      created_at as "Created at",
      account_id as "Account ID",
      region as "Region",
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

node "aws_ecr_repository_node" {
  category = category.ecr_repository

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Registry ID', registry_id,
        'Repository URI', repository_uri,
        'Image Tag Mutability', image_tag_mutability,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ecr_repository
    where
      arn = $1
  EOQ

  param "arn" {}
}

node "aws_ecr_repository_to_ecr_image_node" {
  category = category.ecr_image

  sql = <<-EOQ
    select
      i.image_digest as id,
      i.image_digest as title,
      jsonb_build_object(
        'Manifest Media Type', i.image_manifest_media_type,
        'Artifact Media Type', i.artifact_media_type,
        'Image Size (in Bytes)', i.image_size_in_bytes,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ecr_repository as r
      left join aws_ecr_image i on i.registry_id = i.registry_id and i.repository_name = r.repository_name
    where
      r.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecr_repository_to_ecr_image_edge" {
  title = "image"

  sql = <<-EOQ
    select
      r.arn as from_id,
      i.image_digest as to_id
    from
      aws_ecr_repository as r
      left join aws_ecr_image i on i.registry_id = r.registry_id and i.repository_name = r.repository_name
    where
      r.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ecr_repository_to_ecs_task_definition_node" {
  category = category.ecs_task_definition

  sql = <<-EOQ
    select
      t.task_definition_arn as id,
      t.title as title,
      jsonb_build_object(
        'ARN', t.task_definition_arn,
        'Status', t.status,
        'Image', d ->> 'Image',
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_ecr_repository as r,
      aws_ecs_task_definition as t,
      jsonb_array_elements(container_definitions) as d
    where
      r.repository_uri = split_part(d ->> 'Image', ':', 1)
      and r.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_ecr_repository_to_ecs_task_definition_edge" {
  title = "task definition"

  sql = <<-EOQ
    select
      r.arn as from_id,
      t.task_definition_arn as to_id
    from
      aws_ecr_repository as r,
      aws_ecs_task_definition as t,
      jsonb_array_elements(container_definitions) as d
    where
      r.repository_uri = split_part(d ->> 'Image', ':', 1)
      and r.arn = $1
  EOQ

  param "arn" {}
}

node "aws_ecr_repository_to_kms_key_node" {
  category = category.kms_key

  sql = <<-EOQ
    select
      k.arn as id,
      k.title as title,
      jsonb_build_object(
        'ARN', k.arn,
        'Enabled', enabled,
        'ID', id,
        'Account ID', k.account_id,
        'Region', k.region,
        'Key Manager', k.key_manager
      ) as properties
    from
      aws_ecr_repository as r
      left join aws_kms_key as k on k.arn = r.encryption_configuration ->> 'KmsKey'
    where
      r.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ecr_repository_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      r.arn as from_id,
      k.arn as to_id
    from
      aws_ecr_repository as r
      left join aws_kms_key as k on k.arn = r.encryption_configuration ->> 'KmsKey'
    where
      r.arn = $1;
  EOQ

  param "arn" {}
}
