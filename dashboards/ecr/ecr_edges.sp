edge "ecr_repository_to_codepipeline_pipeline" {
  title = "source provider"

  sql = <<-EOQ
    select
      r.arn as from_id,
      p.arn as to_id
    from
      aws_ecr_repository as r,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Source'
      and a -> 'ActionTypeId' ->> 'Provider' = 'ECR'
      and a -> 'Configuration' ->> 'RepositoryName' = r.repository_name
      and p.arn = any($10;
  EOQ

  param "codepipeline_pipeline_arns" {}
}