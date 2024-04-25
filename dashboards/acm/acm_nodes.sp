node "acm_certificate" {
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
      join unnest($1::text[]) as arn on certificate_arn = arn and account_id = split_part(arn, ':', 5) and region = split_part(arn, ':', 4);

  EOQ

  param "acm_certificate_arns" {}
}

