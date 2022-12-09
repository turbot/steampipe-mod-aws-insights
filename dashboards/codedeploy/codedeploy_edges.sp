edge "codedeploy_app_to_codepipeline_pipeline" {
  title = "deploys"

  sql = <<-EOQ
  select
      p.arn as from_id,
      app.arn as to_id
    from
      aws_codedeploy_app as app,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Deploy'
      and a -> 'ActionTypeId' ->> 'Provider' = 'CodeDeploy'
      and a -> 'Configuration' ->> 'ApplicationName' = app.application_name
      and p.arn = any($1);
  EOQ

  param "codepipeline_pipeline_arns" {}
}