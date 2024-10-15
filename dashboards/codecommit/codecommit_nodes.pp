node "codecommit_repository" {
  category = category.codecommit_repository

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Repository ID', repository_id,
        'Repository Name', repository_name,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_codecommit_repository
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "codecommit_repository_arns" {}
}