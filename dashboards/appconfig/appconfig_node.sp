node "appconfig_application" {
  category = category.appconfig_application

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'ID', id,
        'Description', description,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_appconfig_application
    where
      arn = any($1);
  EOQ

  param "appconfig_application_arns" {}
}