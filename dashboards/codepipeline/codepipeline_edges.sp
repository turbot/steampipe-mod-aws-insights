edge "codepipeline_pipeline_to_s3_bucket" {
  title = "deploys"

  sql = <<-EOQ
    select
      p.arn as from_id,
      b.arn as to_id
    from
      aws_s3_bucket as b,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Deploy'
      and a -> 'ActionTypeId' ->> 'Provider' = 'S3'
      and a -> 'Configuration' ->> 'BucketName' = b.name
      and p.arn = any($1);
  EOQ

  param "codepipeline_pipeline_arns" {}
}