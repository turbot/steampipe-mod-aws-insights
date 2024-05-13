node "ecr_image" {
  category = category.ecr_image

  sql = <<-EOQ
    select
      i.image_digest as id,
      left(split_part(i.image_digest,':',2),12) as title,
      jsonb_build_object(
        'Manifest Media Type', i.image_manifest_media_type,
        'Artifact Media Type', i.artifact_media_type,
        'Image Size (in Bytes)', i.image_size_in_bytes,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ecr_repository as r
      left join aws_ecr_image i on i.registry_id = r.registry_id
      and i.repository_name = r.repository_name
    where
      r.arn = any($1);
  EOQ

  param "ecr_repository_arns" {}
}

node "ecr_image_tag" {
  category = category.ecr_image_tag

  sql = <<-EOQ
    select
      jsonb_array_elements_text(image_tags) as id,
      jsonb_array_elements_text(image_tags) as title,
      jsonb_build_object(
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
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

node "ecr_repository" {
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
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ecr_repository_arns" {}
}