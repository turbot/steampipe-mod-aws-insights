dashboard "aws_acm_certificate_relationships" {
  title = "AWS ACM Certificate Relationships"
  #documentation = file("./dashboards/acm/docs/acm_certificate_relationships.md")
  tags = merge(local.acm_common_tags, {
    type = "Relationships"
  })

  input "certificate_arn" {
    title = "Select a certificate:"
    query = query.aws_acm_certificate_input
    width = 4
  }

  graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_acm_certificate_graph_to_certificate
    args = {
      arn = self.input.certificate_arn.value
    }
    category "aws_acm_certificate" {
      href = "${dashboard.acm_certificate_detail.url_path}?input.certificate_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/acm_certificate_dark.svg"))
    }

    category "aws_cloudfront_distribution" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/cloudfront_distribution_dark.svg"))
    }

    category "aws_api_gateway" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/api_gateway_dark.svg"))
    }

    category "aws_application_load_balancer" {
    }

    category "uses" {
      color = "green"
    }
  }
}

query "aws_acm_certificate_graph_to_certificate" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      title as id,
      domain_name as title,
      'aws_acm_certificate' as category,
      jsonb_build_object(
        'ARN', certificate_arn,
        'Domain Name', domain_name,
        'Certificate Transparency Logging Preference', certificate_transparency_logging_preference,
        'Created At', created_at,
        'Account ID', account_id
      ) as properties
    from
      aws_acm_certificate
    where
      certificate_arn = $1

    -- Cloudfront Distribution - nodes
    union all
    select
      null as from_id,
      null as to_id,
      id as id,
      id as title,
      'aws_cloudfront_distribution' as category,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Enabled', enabled::text,
        'Domain Name', domain_name,
        'Account ID', account_id
      ) as properties
    from
      aws_cloudfront_distribution
    where
      arn in (select jsonb_array_elements_text(in_use_by) from aws_acm_certificate where certificate_arn = $1)

    -- Cloudfront Distribution - Edges
    union all
    select
      d.id as from_id,
      c.title as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', d.account_id
      ) as properties
    from
      aws_acm_certificate as c,
      jsonb_array_elements_text(in_use_by) as arns
      left join aws_cloudfront_distribution as d on d.arn = arns
    where
      certificate_arn = $1
    order by
      category,from_id,to_id
  EOQ

  param "arn" {}
}
