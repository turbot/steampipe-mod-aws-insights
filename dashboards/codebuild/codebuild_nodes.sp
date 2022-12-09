node "codebuild_project" {
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
      arn = any($1);
  EOQ

  param "codebuild_project_arns" {}
}