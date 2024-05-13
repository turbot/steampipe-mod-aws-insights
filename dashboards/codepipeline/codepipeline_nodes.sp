node "codepipeline_pipeline" {
  category = category.codepipeline_pipeline

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Name', name,
        'Created At', created_at,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_codepipeline_pipeline
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "codepipeline_pipeline_arns" {}
}

