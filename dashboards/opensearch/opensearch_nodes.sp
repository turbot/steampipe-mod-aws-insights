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
      domain_endpoint_options ->> 'CustomEndpointCertificateArn' = any($1);
  EOQ

  param "opensearch_arns" {}
}



node "opensearch_domain_name" {
  category = category.opensearch_domain
  sql = <<-EOQ
    select
      arn as id,
      domain_name as title,
      jsonb_build_object(
        'ARN', arn,
        'Domain Name', domain_name,
        'Engine Version', engine_version,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_opensearch_domain
    where
      domain_name = $1; -- Use domain_name instead of arn
  EOQ
  param "opensearch_domain_name" {}
}


