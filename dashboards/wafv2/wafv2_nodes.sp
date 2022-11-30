node "aws_wafv2_web_acl_nodes" {
  category = category.wafv2_web_acl
  sql      = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object (
        'ARN', arn,
        'Title', title,
        'Cloud Watch Metrics Enabled', visibility_config->> 'CloudWatchMetricsEnabled',
        'Capacity', capacity,
        'Account ID', account_id
      ) as properties
    from
      aws_wafv2_web_acl
    where
      arn in
      (
        select
          web_acl_id
        from
          aws_cloudfront_distribution
        where
          arn = any($1)
      );
  EOQ

  param "wafv2_acl_arns" {}
}
