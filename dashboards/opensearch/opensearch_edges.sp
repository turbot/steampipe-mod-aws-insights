edge "opensearch_domain_to_acm_certificate" {
  title = "ssl via"

  sql = <<-EOQ
    select
      domain_endpoint_options ->> 'CustomEndpointCertificateArn' as to_id,
      arn as from_id
    from
      aws_opensearch_domain
    where
      domain_endpoint_options ->> 'CustomEndpointCertificateArn' = any($1);
  EOQ

  param "acm_certificate_arns" {}
}