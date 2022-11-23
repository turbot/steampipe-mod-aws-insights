dashboard "aws_cloudfront_distribution_detail" {
  title         = "AWS CloudFront Distribution Detail"
  documentation = file("./dashboards/cloudfront/docs/cloudfront_distribution_detail.md")

  tags = merge(local.cloudfront_common_tags, {
    type = "Detail"
  })

  input "distribution_arn" {
    title = "Select a distribution:"
    query = query.aws_cloudfront_distribution_input
    width = 4
  }

  container {

    card {
      query = query.aws_cloudfront_distribution_status
      width = 2
      args = {
        arn = self.input.distribution_arn.value
      }
    }

    card {
      query = query.aws_cloudfront_distribution_price_class
      width = 2
      args = {
        arn = self.input.distribution_arn.value
      }
    }

    card {
      query = query.aws_cloudfront_distribution_logging
      width = 2
      args = {
        arn = self.input.distribution_arn.value
      }
    }

    card {
      query = query.aws_cloudfront_distribution_field_level_encryption
      width = 2
      args = {
        arn = self.input.distribution_arn.value
      }
    }

    card {
      query = query.aws_cloudfront_distribution_sni
      width = 2
      args = {
        arn = self.input.distribution_arn.value
      }
    }

  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_cloudfront_distribution_node,
        node.aws_cloudfront_distribution_to_acm_certificate_node,
        node.aws_cloudfront_distribution_from_s3_bucket_node,
        node.aws_cloudfront_distribution_from_ec2_application_load_balancer_node,
        node.aws_cloudfront_distribution_from_media_store_container_node
      ]

      edges = [
        edge.aws_cloudfront_distribution_to_acm_certificate_edge,
        edge.aws_cloudfront_distribution_from_s3_bucket_edge,
        edge.aws_cloudfront_distribution_from_ec2_application_load_balancer_edge,
        edge.aws_cloudfront_distribution_from_media_store_container_edge
      ]

      args = {
        arn = self.input.distribution_arn.value
      }
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_cloudfront_distribution_overview
        args = {
          arn = self.input.distribution_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_cloudfront_distribution_tags
        args = {
          arn = self.input.distribution_arn.value
        }

      }
    }
    container {
      width = 6

      table {
        title = "Restrictions"
        query = query.aws_cloudfront_distribution_restrictions
        args = {
          arn = self.input.distribution_arn.value
        }
      }
    }
  }
}

query "aws_cloudfront_distribution_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id
      ) as tags
    from
      aws_cloudfront_distribution
    order by
      title;
  EOQ
}

query "aws_cloudfront_distribution_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value
    from
      aws_cloudfront_distribution
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudfront_distribution_price_class" {
  sql = <<-EOQ
    select
      'Price Class' as label,
      initcap(price_class) as value
    from
      aws_cloudfront_distribution
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudfront_distribution_logging" {
  sql = <<-EOQ
    select
      'Logging' as label,
      case when logging ->> 'Enabled' = 'false' then 'Disabled' else 'Enabled' end as value,
      case when logging ->> 'Enabled' = 'false' then 'alert' else 'ok' end as type
    from
      aws_cloudfront_distribution
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudfront_distribution_field_level_encryption" {
  sql = <<-EOQ
    select
      'Field Level Encryption' as label,
      case when default_cache_behavior ->> 'FieldLevelEncryptionId' = '' then 'Disabled' else 'Enabled' end as value,
      case when default_cache_behavior ->> 'FieldLevelEncryptionId' = '' then 'alert' else 'ok' end as type
    from
      aws_cloudfront_distribution
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudfront_distribution_sni" {
  sql = <<-EOQ
    select
      'SNI' as label,
      case when viewer_certificate ->> 'SSLSupportMethod' <> 'sni-only' then 'Disabled' else 'Enabled' end as value,
      case when viewer_certificate ->> 'SSLSupportMethod' <> 'sni-only' then 'alert' else 'ok' end as type
    from
      aws_cloudfront_distribution
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_cloudfront_distribution_node" {
  category = category.aws_cloudfront_distribution
  sql      = <<-EOQ
    select
      id as id,
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
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_cloudfront_distribution_to_acm_certificate_node" {
  category = category.aws_acm_certificate
  sql      = <<-EOQ
    select
      certificate_arn as id,
      left(title,8) as title,
      jsonb_build_object (
        'ARN', certificate_arn,
        'Domain Name', domain_name,
        'Certificate Transparency Logging Preference', certificate_transparency_logging_preference,
        'Created At', created_at,
        'Account ID', account_id
      ) as properties
    from
      aws_acm_certificate
    where
      certificate_arn in
      (
        select
          viewer_certificate ->> 'ACMCertificateArn'
        from
          aws_cloudfront_distribution
        where
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_cloudfront_distribution_to_acm_certificate_edge" {
  title = "ssl via"
  sql   = <<-EOQ
    select
      d.id as from_id,
      c.certificate_arn as to_id
    from
      aws_acm_certificate as c
      left join aws_cloudfront_distribution as d on viewer_certificate ->> 'ACMCertificateArn' = certificate_arn
    where
      d.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_cloudfront_distribution_from_s3_bucket_node" {
  category = category.aws_s3_bucket
  sql      = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object (
        'Name', name,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_s3_bucket
    where
      name in
      (
        select distinct
          split_part(origin ->> 'DomainName', '.', 1) as bucket_name
        from
          aws_cloudfront_distribution,
          jsonb_array_elements(origins) as origin
        where
          origin ->> 'DomainName' like '%s3%'
          and arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_cloudfront_distribution_from_s3_bucket_edge" {
  title = "origin for"
  sql   = <<-EOQ
    select
      b.arn as from_id,
      d.id as to_id
    from
      aws_cloudfront_distribution as d,
      jsonb_array_elements(origins) as origin
      left join aws_s3_bucket as b on origin ->> 'DomainName' like '%' || b.name || '%'
    where
      d.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_cloudfront_distribution_from_ec2_application_load_balancer_node" {
  category = category.aws_ec2_application_load_balancer
  sql      = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object (
        'ARN', arn,
        'VPC ID', vpc_id,
        'DNS Name', dns_name,
        'Created Time', created_time,
        'Account ID', account_id
      ) as properties
    from
      aws_ec2_application_load_balancer
    where
      dns_name in
      (
        select
          origin ->> 'DomainName'
        from
          aws_cloudfront_distribution,
          jsonb_array_elements(origins) as origin
        where
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_cloudfront_distribution_from_ec2_application_load_balancer_edge" {
  title = "origin for"
  sql   = <<-EOQ
    select
      b.arn as from_id,
      d.id as to_id
    from
      aws_cloudfront_distribution as d,
      jsonb_array_elements(origins) as origin
      left join aws_ec2_application_load_balancer as b on b.dns_name = origin ->> 'DomainName'
    where
      d.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_cloudfront_distribution_from_media_store_container_node" {
  category = category.aws_media_store_container
  sql      = <<-EOQ
    select
      arn as id,
      name as title,
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
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_cloudfront_distribution_from_media_store_container_edge" {
  title = "origin for"
  sql   = <<-EOQ
    select
      c.arn as from_id,
      d.id as to_id
    from
      aws_cloudfront_distribution as d,
      jsonb_array_elements(origins) as origin
      left join aws_media_store_container as c on c.endpoint = 'https://' || (origin ->> 'DomainName')
    where
      d.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudfront_distribution_overview" {
  sql = <<-EOQ
    select
      domain_name as "Domain Name",
      title as "Title",
      last_modified_time as "Last Modified Time",
      http_version as "HTTP Version",
      is_ipv6_enabled::text as "IPv6 Enabled",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_cloudfront_distribution
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudfront_distribution_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_cloudfront_distribution,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_cloudfront_distribution_restrictions" {
  sql = <<-EOQ
    select
      restrictions -> 'GeoRestriction' -> 'Items' as "Geo Restriction Items",
      restrictions -> 'GeoRestriction' ->> 'Quantity' as "Geo Restriction Quantity",
      restrictions -> 'GeoRestriction' ->> 'RestrictionType' as "Geo Restriction Restriction Type"
    from
      aws_cloudfront_distribution
    where
      arn = $1;
  EOQ

  param "arn" {}
}
