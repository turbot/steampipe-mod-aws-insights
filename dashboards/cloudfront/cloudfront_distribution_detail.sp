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

      with "certificates" {
        sql = <<-EOQ
          select
            viewer_certificate ->> 'ACMCertificateArn' as certificate_arn
          from
            aws_cloudfront_distribution
          where
            viewer_certificate ->> 'ACMCertificateArn' is not null
            and arn = $1
        EOQ

        args = [self.input.distribution_arn.value]
      }

      with "buckets" {
        sql = <<-EOQ
          select
            arn as bucket_arn
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

        args = [self.input.distribution_arn.value]
      }

      with "albs" {
        sql = <<-EOQ
          select
            arn as alb_arn
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

        args = [self.input.distribution_arn.value]
      }

      with "media_stores" {
        sql = <<-EOQ
          select
            arn as mediastore_arn
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

        args = [self.input.distribution_arn.value]
      }

      with "wafv2_web_acls" {
        sql = <<-EOQ
          select
            arn as wafv2_acl_arn
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
                arn = $1
            );
        EOQ

        args = [self.input.distribution_arn.value]
      }

      nodes = [
        node.cloudfront_distribution,
        node.acm_certificate,
        node.s3_bucket,
        node.ec2_application_load_balancer,
        node.media_store_container,
        node.wafv2_web_acl
      ]

      edges = [
        edge.cloudfront_distribution_to_acm_certificate,
        edge.s3_bucket_to_cloudfront_distribution,
        edge.ec2_application_load_balancer_to_cloudfront_distribution,
        edge.media_store_container_to_cloudfront_distribution,
        edge.cloudfront_distribution_to_wafv2_web_acl
      ]

      args = {
        distribution_arns = [self.input.distribution_arn.value]
        bucket_arns       = with.buckets.rows[*].bucket_arn
        certificate_arns  = with.certificates.rows[*].certificate_arn
        alb_arns          = with.albs.rows[*].alb_arn
        mediastore_arns   = with.media_stores.rows[*].mediastore_arn
        wafv2_acl_arns    = with.wafv2_web_acls.rows[*].wafv2_acl_arn
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

edge "cloudfront_distribution_to_acm_certificate" {
  title = "ssl via"

  sql = <<-EOQ
   select
      distribution_arns as from_id,
      certificate_arns as to_id
    from
      unnest($1::text[]) as distribution_arns,
      unnest($2::text[]) as certificate_arns
  EOQ

  param "distribution_arns" {}
  param "certificate_arns" {}
}

edge "s3_bucket_to_cloudfront_distribution" {
  title = "origin for"
  sql   = <<-EOQ
    select
      distribution_arns as to_id,
      bucket_arns as from_id
    from
      unnest($1::text[]) as distribution_arns,
      unnest($2::text[]) as bucket_arns
  EOQ

  param "distribution_arns" {}
  param "bucket_arns" {}
}

edge "ec2_application_load_balancer_to_cloudfront_distribution" {
  title = "origin for"
  sql   = <<-EOQ
    select
      distribution_arns as to_id,
      alb_arns as from_id
    from
      unnest($1::text[]) as distribution_arns,
      unnest($2::text[]) as alb_arns
  EOQ

  param "distribution_arns" {}
  param "alb_arns" {}
}

edge "media_store_container_to_cloudfront_distribution" {
  title = "origin for"
  sql   = <<-EOQ
    select
      distribution_arns as to_id,
      mediastore_arns as from_id
    from
      unnest($1::text[]) as distribution_arns,
      unnest($2::text[]) as mediastore_arns
  EOQ

  param "distribution_arns" {}
  param "mediastore_arns" {}
}

edge "cloudfront_distribution_to_wafv2_web_acl" {
  title = "web acl"
  sql   = <<-EOQ
    select
      distribution_arns as from_id,
      wafv2_acl_arns as to_id
    from
      unnest($1::text[]) as distribution_arns,
      unnest($2::text[]) as wafv2_acl_arns
  EOQ

  param "distribution_arns" {}
  param "wafv2_acl_arns" {}
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
