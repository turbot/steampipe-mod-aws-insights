edge "media_store_container_to_cloudfront_distribution" {
  title = "origin for"

  sql = <<-EOQ
    select
      c.arn as from_id,
      d.arn as to_id
    from
      aws_cloudfront_distribution as d,
      jsonb_array_elements(origins) as origin
      left join aws_media_store_container as c on c.endpoint = 'https://' || (origin ->> 'DomainName')
    where
      d.arn = any($1);
  EOQ

  param "cloudfront_distribution_arns" {}
}