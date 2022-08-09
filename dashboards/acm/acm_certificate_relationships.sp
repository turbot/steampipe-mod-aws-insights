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
      href  = "${dashboard.acm_certificate_detail.url_path}?input.certificate_arn={{.properties.ARN | @uri}}"
      color = "orange"
    }

    category "aws_cloudfront_distribution" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_cloudfront_distribution.svg"))
    }

    category "aws_api_gateway" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_api_gateway.svg"))
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
      certificate_arn as id,
      certificate_arn as title,
      'aws_acm_certificate' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id
      ) as properties
    from
      aws_acm_certificate
    where
      arn = $1


  EOQ

  param "arn" {}
}
