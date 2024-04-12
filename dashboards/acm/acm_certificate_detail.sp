dashboard "acm_certificate_detail" {

  title         = "AWS ACM Certificate Detail"
  documentation = file("./dashboards/acm/docs/acm_certificate_detail.md")

  tags = merge(local.acm_common_tags, {
    type = "Detail"
  })

  input "certificate_arn" {
    title = "Select a certificate:"
    query = query.acm_certificate_input
    width = 4
  }

  container {

    card {
      query = query.acm_certificate_status
      width = 2
      args  = [self.input.certificate_arn.value]
    }

    card {
      query = query.acm_certificate_key_algorithm
      width = 2
      args  = [self.input.certificate_arn.value]
    }
    card {
      query = query.acm_certificate_renewal_eligibility_status
      width = 2
      args  = [self.input.certificate_arn.value]
    }

    card {
      query = query.acm_certificate_validity
      width = 2
      args  = [self.input.certificate_arn.value]
    }

    card {
      query = query.acm_certificate_transparency_logging_status
      width = 2
      args  = [self.input.certificate_arn.value]
    }

  }

  with "cloudfront_distributions_for_acm_certificate" {
    query = query.cloudfront_distributions_for_acm_certificate
    args  = [self.input.certificate_arn.value]
  }

  with "ec2_application_load_balancers_for_acm_certificate" {
    query = query.ec2_application_load_balancers_for_acm_certificate
    args  = [self.input.certificate_arn.value]
  }

  with "ec2_classic_load_balancers_for_acm_certificate" {
    query = query.ec2_classic_load_balancers_for_acm_certificate
    args  = [self.input.certificate_arn.value]
  }

  with "ec2_network_load_balancers_for_acm_certificate" {
    query = query.ec2_network_load_balancers_for_acm_certificate
    args  = [self.input.certificate_arn.value]
  }

  with "opensearch_domains_for_acm_certificate" {
    query = query.opensearch_domains_for_acm_certificate
    args  = [self.input.certificate_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.acm_certificate
        args = {
          acm_certificate_arns = [self.input.certificate_arn.value]
        }
      }

      node {
        base = node.cloudfront_distribution
        args = {
          cloudfront_distribution_arns = with.cloudfront_distributions_for_acm_certificate.rows[*].distribution_arn
        }
      }

      node {
        base = node.ec2_application_load_balancer
        args = {
          ec2_application_load_balancer_arns = with.ec2_application_load_balancers_for_acm_certificate.rows[*].alb_arn
        }
      }

      node {
        base = node.ec2_classic_load_balancer
        args = {
          ec2_classic_load_balancer_arns = with.ec2_classic_load_balancers_for_acm_certificate.rows[*].clb_arn
        }
      }

      node {
        base = node.ec2_network_load_balancer
        args = {
          ec2_network_load_balancer_arns = with.ec2_network_load_balancers_for_acm_certificate.rows[*].nlb_arn
        }
      }

      node {
        base = node.opensearch_domain
        args = {
          opensearch_arns = with.opensearch_domains_for_acm_certificate.rows[*].opensearch_arn
        }
      }

      edge {
        base = edge.cloudfront_distribution_to_acm_certificate
        args = {
          cloudfront_distribution_arns = with.cloudfront_distributions_for_acm_certificate.rows[*].distribution_arn
        }
      }

      edge {
        base = edge.ec2_application_load_balancer_to_acm_certificate
        args = {
          ec2_application_load_balancer_arns = with.ec2_application_load_balancers_for_acm_certificate.rows[*].alb_arn
        }
      }

      edge {
        base = edge.ec2_classic_load_balancer_to_acm_certificate
        args = {
          ec2_classic_load_balancer_arns = with.ec2_classic_load_balancers_for_acm_certificate.rows[*].clb_arn
        }
      }

      edge {
        base = edge.ec2_network_load_balancer_to_acm_certificate
        args = {
          ec2_network_load_balancer_arns = with.ec2_network_load_balancers_for_acm_certificate.rows[*].nlb_arn
        }
      }

      edge {
        base = edge.opensearch_domain_to_acm_certificate
        args = {
          acm_certificate_arns = [self.input.certificate_arn.value]
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
        query = query.acm_certificate_overview
        args  = [self.input.certificate_arn.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.acm_certificate_tags
        args  = [self.input.certificate_arn.value]
      }
    }

    container {
      width = 6

      table {
        title = "In Use By"
        query = query.acm_certificate_in_use_by
        args  = [self.input.certificate_arn.value]
      }
      table {
        title = "Key Usages"
        query = query.acm_certificate_key_usage
        args  = [self.input.certificate_arn.value]
      }

      table {
        title = "Revocation Details"
        query = query.acm_certificate_revocation_detail
        args  = [self.input.certificate_arn.value]
      }
    }

    container {
      width = 12

      table {
        title = "Domain Validation Options"
        query = query.acm_certificate_domain_validation_options
        args  = [self.input.certificate_arn.value]
      }
    }
  }
}

# Input queries

query "acm_certificate_input" {
  sql = <<-EOQ
    select
      title as label,
      certificate_arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_acm_certificate
    order by
      certificate_arn;
  EOQ
}

# With queries

// query "cloudfront_distributions_for_acm_certificate" {
//   sql = <<-EOQ
//     select
//       arn as distribution_arn
//     from
//       aws_cloudfront_distribution
//     where
//       arn in
//       (
//         select
//           jsonb_array_elements_text(in_use_by)
//         from
//           aws_acm_certificate
//         where
//           certificate_arn = $1
//       );
//     EOQ
// } Time: 3.1s. Rows fetched: 1. Hydrate calls: 1.

// query "cloudfront_distributions_for_acm_certificate" {
//   sql = <<-EOQ
//     select
//       arn as distribution_arn
//     from
//       aws_cloudfront_distribution
//     where
//       arn = (
//         select
//           jsonb_array_elements_text(in_use_by)
//         from
//           aws_acm_certificate
//         where
//           certificate_arn = $1
//           and account_id = split_part($1, ':', 5)
//           and region = split_part($1, ':', 4)
//       );
//     EOQ
// } // Time: 2.9s. Rows fetched: 1. Hydrate calls: 1.

query "cloudfront_distributions_for_acm_certificate" {
  sql = <<-EOQ
    with certificate_usage as (
        select
          jsonb_array_elements_text(in_use_by) as in_use_arn
        from
          aws_acm_certificate
        where
          account_id = split_part($1, ':', 5)
          and region = split_part($1, ':', 4)
          and certificate_arn = $1
    )
    select
      d.arn as distribution_arn
    from
      aws_cloudfront_distribution d
    join
      certificate_usage cu on d.arn = cu.in_use_arn;
    EOQ
} // Time: 340ms. Rows fetched: 3. Hydrate calls: 0.

// query "ec2_application_load_balancers_for_acm_certificate" {
//   sql = <<-EOQ
//     select
//       arn as alb_arn
//     from
//       aws_ec2_application_load_balancer
//     where
//       arn in
//       (
//         select
//           jsonb_array_elements_text(in_use_by)
//         from
//           aws_acm_certificate
//         where
//           certificate_arn = $1
//       );
//     EOQ
// } // Time: 2.9s. Rows fetched: 1. Hydrate calls: 0.

query "ec2_application_load_balancers_for_acm_certificate" {
  sql = <<-EOQ
    with certificate_usage as (
      select
        jsonb_array_elements_text(in_use_by) as in_use_arn
      from
        aws_acm_certificate
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and certificate_arn = $1
    )
    select
      alb.arn as alb_arn
    from
      aws_ec2_application_load_balancer alb
    join
      certificate_usage cu on alb.arn = cu.in_use_arn;
    EOQ
} // Time: 384ms. Rows fetched: 3. Hydrate calls: 0.

// query "ec2_classic_load_balancers_for_acm_certificate" {
//   sql = <<-EOQ
//     select
//       arn as clb_arn
//     from
//       aws_ec2_classic_load_balancer
//     where
//       arn in
//       (
//         select
//           jsonb_array_elements_text(in_use_by)
//         from
//           aws_acm_certificate
//         where
//           certificate_arn = $1
//       );
//     EOQ
// } // Time: 1.9s. Rows fetched: 1. Hydrate calls: 0.

query "ec2_classic_load_balancers_for_acm_certificate" {
  sql = <<-EOQ
    with certificate_usage as (
      select
        jsonb_array_elements_text(in_use_by) as in_use_arn
      from
        aws_acm_certificate
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and certificate_arn = $1
    )
    select
      clb.arn as clb_arn
    from
      aws_ec2_classic_load_balancer clb
    join
      certificate_usage cu on clb.arn = cu.in_use_arn;
  EOQ
} // Time: 478ms. Rows fetched: 3. Hydrate calls: 0.

// query "ec2_network_load_balancers_for_acm_certificate" {
//   sql = <<-EOQ
//     select
//       arn as nlb_arn
//     from
//       aws_ec2_network_load_balancer
//     where
//       arn in
//       (
//         select
//           jsonb_array_elements_text(in_use_by)
//         from
//           aws_acm_certificate
//         where
//           certificate_arn = $1
//       );
//     EOQ
// } // Time: 1.9s. Rows fetched: 1. Hydrate calls: 1.

query "ec2_network_load_balancers_for_acm_certificate" {
  sql = <<-EOQ
    with certificate_usage as (
      select
        jsonb_array_elements_text(in_use_by) as in_use_arn
      from
        aws_acm_certificate
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and certificate_arn = $1
    )
    select
      nlb.arn as nlb_arn
    from
      aws_ec2_network_load_balancer nlb
    join
      certificate_usage cu on nlb.arn = cu.in_use_arn;
  EOQ
} // Time: 380ms. Rows fetched: 1. Hydrate calls: 0.

// query "opensearch_domains_for_acm_certificate" {
//   sql = <<-EOQ
//     select
//       arn as opensearch_arn
//     from
//       aws_opensearch_domain
//     where
//       domain_endpoint_options ->> 'CustomEndpointCertificateArn' = $1;
//     EOQ
// } // Time: 3.6s. Rows fetched: 0. Hydrate calls: 0.

query "opensearch_domains_for_acm_certificate" {
  sql = <<-EOQ
    select
      arn as opensearch_arn
    from
      aws_opensearch_domain
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and domain_endpoint_options ->> 'CustomEndpointCertificateArn' = $1;
    EOQ
} // Time: 88ms. Rows fetched: 1. Hydrate calls: 1.

# Card queries

query "acm_certificate_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value
    from
      aws_acm_certificate
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1;
  EOQ
}

query "acm_certificate_key_algorithm" {
  sql = <<-EOQ
    select
      'Key Algorithm' as label,
      key_algorithm as value
    from
      aws_acm_certificate
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1;
  EOQ
}

query "acm_certificate_renewal_eligibility_status" {
  sql = <<-EOQ
    select
      case when renewal_eligibility = 'INELIGIBLE' then 'Ineligible' else 'Eligible' end as value,
      'Renewal Eligibility' as label
    from
      aws_acm_certificate
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1;
  EOQ
}

query "acm_certificate_validity" {
  sql = <<-EOQ
    select
      case when not_after is null or not_after < now() then 'Invalid' else 'Valid' end as value,
      'Validity' as label,
      case when not_after is null or not_after < now() then 'alert' else 'ok' end as type
    from
      aws_acm_certificate
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1;
  EOQ
}

query "acm_certificate_transparency_logging_status" {
  sql = <<-EOQ
    select
      case when certificate_transparency_logging_preference = 'ENABLED' then 'Enabled' else 'Disabled' end as value,
      'Transparency Logging' as label,
      case when certificate_transparency_logging_preference = 'ENABLED' then 'ok' else 'alert' end as "type"
    from
      aws_acm_certificate
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1;
  EOQ
}

# Other detail page queries

query "acm_certificate_overview" {
  sql = <<-EOQ
    select
      domain_name as "Domain Name",
      title as "Title",
      created_at as "Create Date",
      not_after as "Expiry Time",
      issuer as "Issuer",
      type as "Type",
      region as "Region",
      account_id as "Account ID",
      certificate_arn as "ARN"
    from
      aws_acm_certificate
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1;
  EOQ
}

query "acm_certificate_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_acm_certificate,
      jsonb_array_elements(tags_src) as tag
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1
    order by
      tag ->> 'Key';
  EOQ
}

query "acm_certificate_in_use_by" {
  sql = <<-EOQ
    select
      c.certificate_arn as "ARN",
      in_use as "In Use By"
    from
      aws_acm_certificate as c,
      jsonb_array_elements_text(in_use_by) as in_use
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1;
  EOQ
}

query "acm_certificate_revocation_detail" {
  sql = <<-EOQ
    select
      revocation_reason as "Revocation Reason",
      revoked_at as "Revoked At"
    from
      aws_acm_certificate
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1;
  EOQ
}

query "acm_certificate_key_usage" {
  sql = <<-EOQ
    select
      usage ->> 'Name' as "Usage Name",
      key_algorithm as "Key Algorithm"
    from
      aws_acm_certificate as c,
      jsonb_array_elements(extended_key_usages) as usage
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1;
  EOQ
}

query "acm_certificate_domain_validation_options" {
  sql = <<-EOQ
    select
      option ->> 'DomainName' as "Domain Name",
      option ->> 'ResourceRecord' as "Resource Record",
      option ->> 'ValidationDomain' as "Validation Domain",
      option -> 'ValidationEmails' as "Validation Emails",
      option ->> 'ValidationMethod' as "Validation Method",
      option ->> 'ValidationStatus' as "Validation Status"
    from
      aws_acm_certificate as c,
      jsonb_array_elements(domain_validation_options) as option
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and certificate_arn = $1;
  EOQ
}
