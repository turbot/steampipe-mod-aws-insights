node "media_store_container" {
  category = category.media_store_container
  sql      = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object (
        'ARN', arn,
        'Status', status,
        'Access Logging Enabled', access_logging_enabled::text,
        'Creation Time', creation_time,
        'Account ID', account_id
      ) as properties
    from
      aws_media_store_container
    where
      endpoint in
      (
        select
          'https://' || (origin ->> 'DomainName')
        from
          aws_cloudfront_distribution
          join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4),
          jsonb_array_elements(origins) as origin
      );
  EOQ

  param "mediastore_arns" {}
}
