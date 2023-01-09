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
    where
      arn = any($1);
  EOQ

  param "codepipeline_pipeline_arns" {}
}

