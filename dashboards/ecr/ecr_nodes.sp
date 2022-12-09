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
    where
      arn = any($1)
  EOQ

  param "ecr_repository_arns" {}
}
