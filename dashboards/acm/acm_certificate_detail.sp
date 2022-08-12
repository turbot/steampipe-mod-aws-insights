dashboard "acm_certificate_detail" {

  title         = "AWS ACM Certificate Detail"
  documentation = file("./dashboards/acm/docs/acm_certificate_detail.md")

  tags = merge(local.acm_common_tags, {
    type = "Detail"
  })

  input "certificate_arn" {
    title = "Select a certificate:"
    sql   = query.aws_acm_certificate_input.sql
    width = 4
  }

  container {

    card {
      query = query.aws_acm_certificate_status
      width = 2
      args = {
        arn = self.input.certificate_arn.value
      }
    }

    card {
      query = query.aws_acm_certificate_key_algorithm
      width = 2
      args = {
        arn = self.input.certificate_arn.value
      }
    }
    card {
      query = query.aws_acm_certificate_renewal_eligibility_status
      width = 2
      args = {
        arn = self.input.certificate_arn.value
      }
    }

    card {
      query = query.aws_acm_certificate_validity
      width = 2
      args = {
        arn = self.input.certificate_arn.value
      }
    }

    card {
      query = query.aws_acm_certificate_transparency_logging_status
      width = 2
      args = {
        arn = self.input.certificate_arn.value
      }
    }

  }

  container {
    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_acm_certificate_relationships_graph
      args = {
        arn = self.input.certificate_arn.value
      }
      category "aws_acm_certificate" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/acm_certificate_light.svg"))
      }

      category "aws_cloudfront_distribution" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/cloudfront_distribution_light.svg"))
      }

      category "aws_ec2_classic_load_balancer" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_classic_load_balancer_light.svg"))
      }

      category "aws_ec2_application_load_balancer" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_application_load_balancer_light.svg"))
      }

      category "aws_ec2_network_load_balancer" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_network_load_balancer_light.svg"))
      }

      category "uses" {
        color = "green"
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
        query = query.aws_acm_certificate_overview
        args = {
          arn = self.input.certificate_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_acm_certificate_tags
        args = {
          arn = self.input.certificate_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "In Use By"
        query = query.aws_acm_certificate_in_use_by
        args = {
          arn = self.input.certificate_arn.value
        }
      }
      table {
        title = "Key Usages"
        query = query.aws_acm_certificate_key_usage
        args = {
          arn = self.input.certificate_arn.value
        }
      }

      table {
        title = "Revocation Details"
        query = query.aws_acm_certificate_revocation_detail
        args = {
          arn = self.input.certificate_arn.value
        }
      }
    }

    container {
      width = 12

      table {
        title = "Domain Validation Options"
        query = query.aws_acm_certificate_domain_validation_options
        args = {
          arn = self.input.certificate_arn.value
        }
      }

    }

  }
}

query "aws_acm_certificate_input" {
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

query "aws_acm_certificate_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value
    from
      aws_acm_certificate
    where
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_key_algorithm" {
  sql = <<-EOQ
    select
      'Key Algorithm' as label,
      key_algorithm as value
    from
      aws_acm_certificate
    where
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_renewal_eligibility_status" {
  sql = <<-EOQ
    select
      case when renewal_eligibility = 'INELIGIBLE' then 'Ineligible' else 'Eligible' end as value,
      'Renewal Eligibility' as label
    from
      aws_acm_certificate
    where
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_validity" {
  sql = <<-EOQ
    select
      case when not_after is null or not_after < now() then 'Invalid' else 'Valid' end as value,
      'Validity' as label,
      case when not_after is null or not_after < now() then 'alert' else 'ok' end as type
    from
      aws_acm_certificate
    where
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_transparency_logging_status" {
  sql = <<-EOQ
    select
      case when certificate_transparency_logging_preference = 'ENABLED' then 'Enabled' else 'Disabled' end as value,
      'Transparency Logging' as label,
      case when certificate_transparency_logging_preference = 'ENABLED' then 'ok' else 'alert' end as "type"
    from
      aws_acm_certificate
    where
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_relationships_graph" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      title as id,
      title as title,
      'aws_acm_certificate' as category,
      jsonb_build_object( 'ARN', certificate_arn, 'Domain Name', domain_name, 'Certificate Transparency Logging Preference', certificate_transparency_logging_preference, 'Created At', created_at, 'Account ID', account_id ) as properties
    from
      aws_acm_certificate
    where
      certificate_arn = $1

    -- From Cloudfront Distributions (node)
    union all
    select
      null as from_id,
      null as to_id,
      id as id,
      id as title,
      'aws_cloudfront_distribution' as category,
      jsonb_build_object( 'ARN', arn, 'Status', status, 'Enabled', enabled::text, 'Domain Name', domain_name, 'Account ID', account_id ) as properties
    from
      aws_cloudfront_distribution
    where
      arn in
      (
        select
          jsonb_array_elements_text(in_use_by)
        from
          aws_acm_certificate
        where
          certificate_arn = $1
      )

    -- From Cloudfront Distributions (edge)
    union all
    select
      d.id as from_id,
      c.title as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', d.account_id ) as properties
    from
      aws_acm_certificate as c,
      jsonb_array_elements_text(in_use_by) as arns
      left join
        aws_cloudfront_distribution as d
        on d.arn = arns
    where
      certificate_arn = $1

    -- From EC2 Classic Load Balancers (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_ec2_classic_load_balancer' as category,
      jsonb_build_object( 'ARN', arn, 'VPC ID', vpc_id, 'DNS Name', dns_name, 'Created Time', created_time, 'Account ID', account_id ) as properties
    from
      aws_ec2_classic_load_balancer
    where
      arn in
      (
        select
          jsonb_array_elements_text(in_use_by)
        from
          aws_acm_certificate
        where
          certificate_arn = $1
      )

    -- From EC2 Classic Load Balancers (edge)
    union all
    select
      b.arn as from_id,
      c.title as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', b.account_id ) as properties
    from
      aws_acm_certificate as c,
      jsonb_array_elements_text(in_use_by) as arns
      left join
        aws_ec2_classic_load_balancer as b
        on b.arn = arns
    where
      certificate_arn = $1

    -- From EC2 Application Load Balancers (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_ec2_application_load_balancer' as category,
      jsonb_build_object( 'ARN', arn, 'VPC ID', vpc_id, 'DNS Name', dns_name, 'Created Time', created_time, 'Account ID', account_id ) as properties
    from
      aws_ec2_application_load_balancer
    where
      arn like '%loadbalancer/app%'
      and arn in
      (
        select
          jsonb_array_elements_text(in_use_by)
        from
          aws_acm_certificate
        where
          certificate_arn = $1
      )

    -- From EC2 Application Load Balancers (edge)
    union all
    select
      lb.arn as from_id,
      c.title as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', lb.account_id ) as properties
    from
      aws_acm_certificate as c,
      jsonb_array_elements_text(in_use_by) as arns
      left join
        aws_ec2_application_load_balancer as lb
        on lb.arn = arns
    where
      certificate_arn = $1
      and lb.arn like '%loadbalancer/app%'

    -- From EC2 Network Load Balancers (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_ec2_network_load_balancer' as category,
      jsonb_build_object( 'ARN', arn, 'VPC ID', vpc_id, 'DNS Name', dns_name, 'Created Time', created_time, 'Account ID', account_id ) as properties
    from
      aws_ec2_network_load_balancer
    where
      arn in
      (
        select
          jsonb_array_elements_text(in_use_by)
        from
          aws_acm_certificate
        where
          certificate_arn = $1
      )

    -- From EC2 Network Load Balancers (edge)
    union all
    select
      b.arn as from_id,
      c.title as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', b.account_id ) as properties
    from
      aws_acm_certificate as c,
      jsonb_array_elements_text(in_use_by) as arns
      left join
        aws_ec2_network_load_balancer as b
        on b.arn = arns
    where
      certificate_arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_overview" {
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
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_acm_certificate,
      jsonb_array_elements(tags_src) as tag
    where
      certificate_arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_in_use_by" {
  sql = <<-EOQ
    select
      c.certificate_arn as "ARN",
      in_use as "In Use By"
    from
      aws_acm_certificate as c,
      jsonb_array_elements_text(in_use_by) as in_use
    where
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_revocation_detail" {
  sql = <<-EOQ
    select
      revocation_reason as "Revocation Reason",
      revoked_at as "Revoked At"
    from
      aws_acm_certificate
    where
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_key_usage" {
  sql = <<-EOQ
    select
      usage ->> 'Name' as "Usage Name",
      key_algorithm as "Key Algorithm"
    from
      aws_acm_certificate as c,
      jsonb_array_elements(extended_key_usages) as usage
    where
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_domain_validation_options" {
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
      certificate_arn = $1;
  EOQ

  param "arn" {}
}
