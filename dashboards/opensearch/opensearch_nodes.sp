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
    where
      arn = any($1);
  EOQ

  param "opensearch_arns" {}
}
