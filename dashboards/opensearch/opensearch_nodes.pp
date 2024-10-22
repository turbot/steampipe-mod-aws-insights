node "opensearch_domain" {
  category = category.opensearch_domain

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Domain ID', domain_id,
        'Domain Name', domain_name,
        'Engine Version', engine_version,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_opensearch_domain
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "opensearch_arns" {}
}
