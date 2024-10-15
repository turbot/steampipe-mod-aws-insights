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
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "codebuild_project_arns" {}
}