edge "ecr_image_to_ecr_image_tag" {
  title = "tag"

  sql = <<-EOQ
    with ecr_image as (
      select
        registry_id,
        image_digest,
        image_tags,
        repository_name
      from
        aws_ecr_image
    ), ecr_repository as (
      select
        arn,
        registry_id,
        repository_name
      from
        aws_ecr_repository
      where
        arn = any($1)
    )
    select
      i.image_digest as from_id,
      jsonb_array_elements_text(image_tags) as to_id
    from
      ecr_repository as r
      left join ecr_image i on i.registry_id = r.registry_id and i.repository_name = r.repository_name;
  EOQ

  param "ecr_repository_arns" {}
}

edge "ecr_repository_to_ecr_image" {
  title = "image"

  sql = <<-EOQ
    with ecr_image as (
      select
        image_digest,
        registry_id,
        repository_name
      from
        aws_ecr_image
    ), ecr_repository as (
      select
        arn,
        registry_id,
        repository_name
      from
        aws_ecr_repository
      where
        arn = any($1)
    )
    select
      r.arn as from_id,
      i.image_digest as to_id
    from
      ecr_repository as r
      left join ecr_image i on i.registry_id = r.registry_id and i.repository_name = r.repository_name;
  EOQ

  param "ecr_repository_arns" {}
}

edge "ecr_repository_to_ecs_task_definition" {
  title = "task definition"

  sql = <<-EOQ
    with ecs_task_definition as (
      select
        container_definitions,
        task_definition_arn
      from
        aws_ecs_task_definition
    )
    select
      r.arn as from_id,
      t.task_definition_arn as to_id
    from
      aws_ecr_repository as r
      join unnest($1::text[]) as a on r.arn = a and r.account_id = split_part(a, ':', 5) and r.region = split_part(a, ':', 4),
      ecs_task_definition as t,
      jsonb_array_elements(container_definitions) as d
    where
      r.repository_uri = split_part(d ->> 'Image', ':', 1);
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
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ecr_repository_arns" {}
}