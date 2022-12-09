dashboard "ecr_repository_detail" {

  title         = "AWS ECR Repository Detail"
  documentation = file("./dashboards/ecr/docs/ecr_repository_detail.md")

  tags = merge(local.ecr_common_tags, {
    type = "Detail"
  })

  input "ecr_repository_arn" {
    title = "Select a Repository:"
    query = query.ecr_repository_input
    width = 4
  }

  container {

    card {
      query = query.ecr_repository_encrypted
      width = 2
      args = {
        arn = self.input.ecr_repository_arn.value
      }
    }

    card {
      query = query.ecr_repository_scan_on_push
      width = 2
      args = {
        arn = self.input.ecr_repository_arn.value
      }
    }

    card {
      query = query.ecr_repository_tagging
      width = 2
      args = {
        arn = self.input.ecr_repository_arn.value
      }
    }

    card {
      query = query.ecr_repository_tag_immutability
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

      with "ecs_task_definitions" {
        sql = <<-EOQ
          select
            t.task_definition_arn as task_definition_arn
          from
            aws_ecr_repository as r,
            aws_ecs_task_definition as t,
            jsonb_array_elements(container_definitions) as d
          where
            r.repository_uri = split_part(d ->> 'Image', ':', 1)
            and r.arn = $1
        EOQ

        args = [self.input.ecr_repository_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            encryption_configuration ->> 'KmsKey' as kms_key_arn
          from
            aws_ecr_repository
          where
            arn = $1;
        EOQ

        args = [self.input.ecr_repository_arn.value]
      }

      nodes = [
        node.ecr_image,
        node.ecr_image_tag,
        node.ecr_repository,
        node.ecs_task_definition,
        node.kms_key
      ]

      edges = [
        edge.ecr_image_to_ecr_image_tag,
        edge.ecr_repository_to_ecr_image,
        edge.ecr_repository_to_ecs_task_definition,
        edge.ecr_repository_to_kms_key
      ]

      args = {
        ecr_repository_arns      = [self.input.ecr_repository_arn.value]
        ecs_task_definition_arns = with.ecs_task_definitions.rows[*].task_definition_arn
        kms_key_arns             = with.kms_keys.rows[*].kms_key_arn
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
        query = query.ecr_repository_overview
        args = {
          arn = self.input.ecr_repository_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.ecr_repository_tags
        args = {
          arn = self.input.ecr_repository_arn.value
        }
      }
    }
  }
}

query "ecr_repository_encrypted" {
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

query "ecr_repository_tagging" {
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

query "ecr_repository_public_access" {
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

query "ecr_repository_tag_immutability" {
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

query "ecr_repository_scan_on_push" {
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

query "ecr_repository_overview" {
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

query "ecr_repository_tags" {
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

query "ecr_repository_input" {
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

