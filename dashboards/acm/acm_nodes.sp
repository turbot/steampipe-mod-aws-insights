node "aws_acm_certificate_nodes" {
  category = category.acm_certificate

  sql = <<-EOQ
    select
      certificate_arn as id,
      domain_name || ' ['|| left(title,8) || ']' as title,
      jsonb_build_object (
        'ARN', certificate_arn,
        'Domain Name', domain_name,
        'Certificate Transparency Logging Preference', certificate_transparency_logging_preference,
        'Status', status,
        'Created At', created_at,
        'Issued At', issued_at,
        'Type', type,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_acm_certificate
    where
      certificate_arn = any($1);
  EOQ

  param "certificate_arns" {}
}

