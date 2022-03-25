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
  sql = <<EOQ
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
      'Renewal Eligibility Status' as label
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
      'Transparency Logging Status' as label,
      case when certificate_transparency_logging_preference = 'ENABLED' then 'ok' else 'alert' end as "type"
    from
      aws_acm_certificate
    where
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_acm_certificate_overview" {
  sql = <<-EOQ
    select
      domain_name as "Domain Name",
      title as "Title",
      created_at as "Create Date",
      issuer as "Issuer",
      status as "Status",
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
  sql = <<EOQ
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
  sql = <<EOQ
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
  sql = <<EOQ
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
  sql = <<EOQ
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
