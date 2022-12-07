edge "s3_bucket_to_cloudfront_distribution" {
  title = "origin for"

  sql = <<-EOQ
    select
      b.arn as from_id,
      d.arn as to_id
    from
      aws_cloudfront_distribution as d,
      jsonb_array_elements(origins) as origin
      left join aws_s3_bucket as b on origin ->> 'DomainName' like '%' || b.name || '%'
    where
      d.arn = any($1);
  EOQ

  param "cloudfront_distribution_arns" {}
}