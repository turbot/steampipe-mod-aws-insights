edge "cloudfront_distribution_to_acm_certificate" {
  title = "ssl via"

  sql = <<-EOQ
    select
      arn as from_id,
      viewer_certificate ->> 'ACMCertificateArn' as to_id
    from
      aws_cloudfront_distribution
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "cloudfront_distribution_arns" {}
}

edge "cloudfront_distribution_to_wafv2_web_acl" {
  title = "web acl"

  sql = <<-EOQ
    select
      d.arn as from_id,
      c.arn as to_id
    from
      aws_wafv2_web_acl as c
      left join aws_cloudfront_distribution as d on d.web_acl_id = c.arn
    where
      d.arn = any($1);
  EOQ

  param "cloudfront_distribution_arns" {}
}