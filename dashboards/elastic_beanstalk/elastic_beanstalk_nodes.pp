node "elastic_beanstalk_application" {
  category = category.elastic_beanstalk

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Name', name,
        'Date Created',date_created,
        'Description', description,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_elastic_beanstalk_application
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "elastic_beanstalk_application_arns" {}
}