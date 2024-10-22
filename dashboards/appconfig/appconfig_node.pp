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
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "appconfig_application_arns" {}
}