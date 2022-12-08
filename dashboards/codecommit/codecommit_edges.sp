edge "codecommit_repository_to_codebuild_project" {
  title = "codebuild project"

  sql = <<-EOQ
    select
      r.arn as from_id,
      p.arn as to_id
    from
      aws_codecommit_repository r
      left join aws_codebuild_project p on r.clone_url_http in (
        select
          source ->> 'Location' as "l"
        from aws_codebuild_project
        union all
        select
          s ->> 'Location' as "l"
        from aws_codebuild_project,
          jsonb_array_elements(aws_codebuild_project.secondary_sources) as s
      )
    where
      r.arn = any($1);
  EOQ

  param "codecommit_repository_arns" {}
}

edge "codecommit_repository_to_codepipeline_pipeline" {
  title = "codepipeline pipeline"

  sql = <<-EOQ
    select
      r.arn as from_id,
      p.arn as to_id
    from
      aws_codecommit_repository as r,
      aws_codepipeline_pipeline as p,
      jsonb_array_elements(stages) as s,
      jsonb_array_elements(s -> 'Actions') as a
    where
      s ->> 'Name' = 'Source'
      and a -> 'ActionTypeId' ->> 'Provider' = 'CodeCommit'
      and r.repository_name = a -> 'Configuration' ->> 'RepositoryName'
      and r.arn = any($1)
  EOQ

  param "codecommit_repository_arns" {}
}