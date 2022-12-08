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