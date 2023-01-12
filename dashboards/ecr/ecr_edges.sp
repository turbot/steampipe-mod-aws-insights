edge "ecr_image_to_ecr_image_tag" {
  title = "tag"

  sql = <<-EOQ
    select
      i.image_digest as from_id,
      jsonb_array_elements_text(image_tags) as to_id
    from
      aws_ecr_repository as r
      left join aws_ecr_image i
      on i.registry_id = r.registry_id
      and i.repository_name = r.repository_name
    where
      r.arn = any($1);
  EOQ

  param "ecr_repository_arns" {}
}

edge "ecr_repository_to_ecr_image" {
  title = "image"

  sql = <<-EOQ
    select
      r.arn as from_id,
      i.image_digest as to_id
    from
      aws_ecr_repository as r
      left join aws_ecr_image i on i.registry_id = r.registry_id and i.repository_name = r.repository_name
    where
      r.arn = any($1);
  EOQ

  param "ecr_repository_arns" {}
}

edge "ecr_repository_to_ecs_task_definition" {
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
      and r.arn = any($1);
  EOQ

  param "ecr_repository_arns" {}
}

edge "ecr_repository_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      encryption_configuration ->> 'KmsKey' as to_id
    from
      aws_ecr_repository
    where
      arn = any($1);
  EOQ

  param "ecr_repository_arns" {}
}