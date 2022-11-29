node "aws_media_store_container_nodes" {
  category = category.aws_media_store_container
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
          aws_cloudfront_distribution,
          jsonb_array_elements(origins) as origin
        where
          arn = any($1)
      );
  EOQ

  param "mediastore_arns" {}
}
