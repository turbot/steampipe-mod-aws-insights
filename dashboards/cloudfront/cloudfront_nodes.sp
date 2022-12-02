node "cloudfront_distribution" {
  category = category.cloudfront_distribution
  sql      = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object (
        'ARN', arn,
        'Status', status,
        'Enabled', enabled::text,
        'Domain Name', domain_name,
        'Account ID', account_id
      ) as properties
    from
      aws_cloudfront_distribution
    where
      arn = any($1);
  EOQ

  param "cloudfront_distribution_arns" {}
}
