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
    where
      arn = any($1);
  EOQ

  param "elastic_beanstalk_application_arns" {}
}