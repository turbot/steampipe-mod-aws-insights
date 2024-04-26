node "codedeploy_app" {
  category = category.codedeploy_app

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Name', application_name,
        'Create Time', create_time,
        'Compute Platform', compute_platform,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_codedeploy_app
    where
      application_name in
      (
        select
          a -> 'Configuration' ->> 'ApplicationName'
        from
          aws_codepipeline_pipeline
          join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4),
          jsonb_array_elements(stages) as s,
          jsonb_array_elements(s -> 'Actions') as a
        where
          s ->> 'Name' = 'Deploy'
          and a -> 'ActionTypeId' ->> 'Provider' = 'CodeDeploy'
      );
  EOQ

  param "codepipeline_pipeline_arns" {}
}