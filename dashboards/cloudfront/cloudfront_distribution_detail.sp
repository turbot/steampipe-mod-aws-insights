dashboard "cloudfront_distribution_detail" {
  title         = "AWS CloudFront Distribution Detail"
  documentation = file("./dashboards/cloudfront/docs/cloudfront_distribution_detail.md")

  tags = merge(local.cloudfront_common_tags, {
    type = "Detail"
  })

  input "distribution_arn" {
    title = "Select a distribution:"
    query = query.cloudfront_distribution_input
    width = 4
  }

  container {

    card {
      query = query.cloudfront_distribution_status
      width = 2
      args  = [self.input.distribution_arn.value]
    }

    card {
      query = query.cloudfront_distribution_price_class
      width = 2
      args  = [self.input.distribution_arn.value]
    }

    card {
      query = query.cloudfront_distribution_logging
      width = 2
      args  = [self.input.distribution_arn.value]
    }

    card {
      query = query.cloudfront_distribution_field_level_encryption
      width = 2
      args  = [self.input.distribution_arn.value]
    }

    card {
      query = query.cloudfront_distribution_sni
      width = 2
      args  = [self.input.distribution_arn.value]
    }

  }

  with "acm_certificates_for_cloudfront_distribution" {
    query = query.acm_certificates_for_cloudfront_distribution
    args  = [self.input.distribution_arn.value]
  }

  with "ec2_application_load_balancers_for_cloudfront_distribution" {
    query = query.ec2_application_load_balancers_for_cloudfront_distribution
    args  = [self.input.distribution_arn.value]
  }

  with "media_stores_for_cloudfront_distribution" {
    query = query.media_stores_for_cloudfront_distribution
    args  = [self.input.distribution_arn.value]
  }

  with "s3_buckets_for_cloudfront_distribution" {
    query = query.s3_buckets_for_cloudfront_distribution
    args  = [self.input.distribution_arn.value]
  }

  with "wafv2_web_acls_for_cloudfront_distribution" {
    query = query.wafv2_web_acls_for_cloudfront_distribution
    args  = [self.input.distribution_arn.value]
  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.acm_certificate
        args = {
          acm_certificate_arns = with.acm_certificates_for_cloudfront_distribution.rows[*].certificate_arn
        }
      }

      node {
        base = node.cloudfront_distribution
        args = {
          cloudfront_distribution_arns = [self.input.distribution_arn.value]
        }
      }

      node {
        base = node.ec2_application_load_balancer
        args = {
          ec2_application_load_balancer_arns = with.ec2_application_load_balancers_for_cloudfront_distribution.rows[*].alb_arn
        }
      }

      node {
        base = node.media_store_container
        args = {
          mediastore_arns = with.media_stores_for_cloudfront_distribution.rows[*].mediastore_arn
        }
      }

      node {
        base = node.s3_bucket
        args = {
          s3_bucket_arns = with.s3_buckets_for_cloudfront_distribution.rows[*].bucket_arn
        }
      }

      node {
        base = node.wafv2_web_acl
        args = {
          wafv2_acl_arns = with.wafv2_web_acls_for_cloudfront_distribution.rows[*].wafv2_acl_arn
        }
      }

      edge {
        base = edge.cloudfront_distribution_to_acm_certificate
        args = {
          cloudfront_distribution_arns = [self.input.distribution_arn.value]
        }
      }

      edge {
        base = edge.cloudfront_distribution_to_wafv2_web_acl
        args = {
          cloudfront_distribution_arns = [self.input.distribution_arn.value]
        }
      }

      edge {
        base = edge.ec2_application_load_balancer_to_cloudfront_distribution
        args = {
          cloudfront_distribution_arns = [self.input.distribution_arn.value]
        }
      }

      edge {
        base = edge.media_store_container_to_cloudfront_distribution
        args = {
          cloudfront_distribution_arns = [self.input.distribution_arn.value]
        }
      }

      edge {
        base = edge.s3_bucket_to_cloudfront_distribution
        args = {
          cloudfront_distribution_arns = [self.input.distribution_arn.value]
        }
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
        query = query.cloudfront_distribution_overview
        args  = [self.input.distribution_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.cloudfront_distribution_tags
        args  = [self.input.distribution_arn.value]

      }
    }
    container {
      width = 6

      table {
        title = "Restrictions"
        query = query.cloudfront_distribution_restrictions
        args  = [self.input.distribution_arn.value]
      }
    }
  }
}

# Input queries

query "cloudfront_distribution_input" {
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

# With queries

query "acm_certificates_for_cloudfront_distribution" {
  sql = <<-EOQ
    select
      viewer_certificate ->> 'ACMCertificateArn' as certificate_arn
    from
      aws_cloudfront_distribution
    where
      viewer_certificate ->> 'ACMCertificateArn' is not null
      and arn = $1
      and account_id = split_part($1,':',5);
  EOQ
}

// query "ec2_application_load_balancers_for_cloudfront_distribution" {
//   sql = <<-EOQ
//     select
//       b.arn as alb_arn
//     from
//       aws_cloudfront_distribution as d,
//       jsonb_array_elements(origins) as origin
//       left join aws_ec2_application_load_balancer as b on b.dns_name = origin ->> 'DomainName'
//     where
//       b.arn is not null
//       and d.arn = $1;
//     EOQ
// } // Time: 4.2s. Rows fetched: 2. Hydrate calls: 2.

query "ec2_application_load_balancers_for_cloudfront_distribution" {
  sql = <<-EOQ
    with distribution_origins as (
      select
        jsonb_array_elements(origins) ->> 'DomainName' as domain_name
      from
        aws_cloudfront_distribution
      where
        arn = $1
        and account_id = split_part($1,':',5)
    ),
    linked_albs as (
      select
        b.arn as alb_arn,
        b.dns_name
      from
        aws_ec2_application_load_balancer b
      join
        distribution_origins d on b.dns_name = d.domain_name
      where
        b.account_id = split_part($1,':',5)
    )
    select
      alb_arn
    from
      linked_albs
    where
      alb_arn is not null;
  EOQ
} // Time: 2.7s. Rows fetched: 2. Hydrate calls: 2.

// query "media_stores_for_cloudfront_distribution" {
//   sql = <<-EOQ
//     select
//       arn as mediastore_arn
//     from
//       aws_media_store_container
//     where
//       endpoint in
//       (
//         select
//           'https://' || (origin ->> 'DomainName')
//         from
//           aws_cloudfront_distribution,
//           jsonb_array_elements(origins) as origin
//         where
//           arn = $1
//       );
//   EOQ
// } // Time: 2.2s. Rows fetched: 2. Hydrate calls: 2.

query "media_stores_for_cloudfront_distribution" {
  sql = <<-EOQ
    select
      arn as mediastore_arn
    from
      aws_media_store_container
    where
      account_id = split_part($1,':',5)
      and endpoint in
      (
        select
          'https://' || (origin ->> 'DomainName')
        from
          aws_cloudfront_distribution,
          jsonb_array_elements(origins) as origin
        where
          arn = $1
          and account_id = split_part($1,':',5)
      );
  EOQ
} // Time: 321ms. Rows fetched: 2. Hydrate calls: 2. 

// query "s3_buckets_for_cloudfront_distribution" {
//   sql = <<-EOQ
//     select
//       arn as bucket_arn
//     from
//       aws_s3_bucket
//     where
//       name in
//       (
//         select distinct
//           split_part(origin ->> 'DomainName', '.', 1) as bucket_name
//         from
//           aws_cloudfront_distribution,
//           jsonb_array_elements(origins) as origin
//         where
//           origin ->> 'DomainName' like '%s3%'
//           and arn = $1
//       );
//   EOQ
// } // Time: 4.0s. Rows fetched: 2. Hydrate calls: 2.

query "s3_buckets_for_cloudfront_distribution" {
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
          and account_id = split_part($1,':',5)
      );
  EOQ
} // Time: 2.7s. Rows fetched: 2. Hydrate calls: 2.

// query "wafv2_web_acls_for_cloudfront_distribution" {
//   sql = <<-EOQ
//     select
//       arn as wafv2_acl_arn
//     from
//       aws_wafv2_web_acl
//     where
//       arn in
//       (
//         select
//           web_acl_id
//         from
//           aws_cloudfront_distribution
//         where
//           arn = $1
//           and account_id = split_part($1,':',5)
//       )
//       and account_id = split_part($1,':',5);
//   EOQ
// } // Time: 6.4s. Rows fetched: 2. Hydrate calls: 2.

query "wafv2_web_acls_for_cloudfront_distribution" {
  sql = <<-EOQ
    with cloudfront_web_acl as (
      select
        web_acl_id
      from
        aws_cloudfront_distribution
      where
        arn = $1
        and account_id = split_part($1,':',5)
    )
    select
      waf.arn as wafv2_acl_arn
    from
      aws_wafv2_web_acl waf
    join
      cloudfront_web_acl cwa on waf.arn = cwa.web_acl_id
    where
    account_id = split_part($1,':',5);
  EOQ
} // Time: 397ms. Rows fetched: 2. Hydrate calls: 2.

# Card queries

query "cloudfront_distribution_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value
    from
      aws_cloudfront_distribution
    where
      arn = $1
      and account_id = split_part($1,':',5);
  EOQ
}

query "cloudfront_distribution_price_class" {
  sql = <<-EOQ
    select
      'Price Class' as label,
      initcap(price_class) as value
    from
      aws_cloudfront_distribution
    where
      arn = $1
      and account_id = split_part($1,':',5);
  EOQ
}

query "cloudfront_distribution_logging" {
  sql = <<-EOQ
    select
      'Logging' as label,
      case when logging ->> 'Enabled' = 'false' then 'Disabled' else 'Enabled' end as value,
      case when logging ->> 'Enabled' = 'false' then 'alert' else 'ok' end as type
    from
      aws_cloudfront_distribution
    where
      arn = $1
      and account_id = split_part($1,':',5);
  EOQ
}

query "cloudfront_distribution_field_level_encryption" {
  sql = <<-EOQ
    select
      'Field Level Encryption' as label,
      case when default_cache_behavior ->> 'FieldLevelEncryptionId' = '' then 'Disabled' else 'Enabled' end as value,
      case when default_cache_behavior ->> 'FieldLevelEncryptionId' = '' then 'alert' else 'ok' end as type
    from
      aws_cloudfront_distribution
    where
      arn = $1
      and account_id = split_part($1,':',5);
  EOQ
}

query "cloudfront_distribution_sni" {
  sql = <<-EOQ
    select
      'SNI' as label,
      case when viewer_certificate ->> 'SSLSupportMethod' <> 'sni-only' then 'Disabled' else 'Enabled' end as value,
      case when viewer_certificate ->> 'SSLSupportMethod' <> 'sni-only' then 'alert' else 'ok' end as type
    from
      aws_cloudfront_distribution
    where
      arn = $1
      and account_id = split_part($1,':',5);
  EOQ
}

# Other detail page queries

query "cloudfront_distribution_overview" {
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
      arn = $1
      and account_id = split_part($1,':',5);
  EOQ
}

query "cloudfront_distribution_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_cloudfront_distribution,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
      and account_id = split_part($1,':',5)
    order by
      tag ->> 'Key';
  EOQ
}

query "cloudfront_distribution_restrictions" {
  sql = <<-EOQ
    select
      restrictions -> 'GeoRestriction' -> 'Items' as "Geo Restriction Items",
      restrictions -> 'GeoRestriction' ->> 'Quantity' as "Geo Restriction Quantity",
      restrictions -> 'GeoRestriction' ->> 'RestrictionType' as "Geo Restriction Restriction Type"
    from
      aws_cloudfront_distribution
    where
      arn = $1
      and account_id = split_part($1,':',5);
  EOQ
}
