query "aws_acm_certificate_input" {
  sql = <<EOQ
    select
      certificate_arn as label,
      certificate_arn as value
    from
      aws_acm_certificate
    order by
      certificate_arn;
EOQ
}

query "aws_acm_certificate_domain_name" {
  sql = <<-EOQ
    select
      domain_name as "Domain Name"
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

query "aws_acm_certificate_renewal_eligibility_status" {
  sql = <<-EOQ
    select
      case when renewal_eligibility = 'INELIGIBLE' then 'Ineligible' else 'Eligible' end as value,
      'Renewal Eligibility Status' as label,
      case when renewal_eligibility = 'INELIGIBLE' then 'alert' else 'ok' end as "type"
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
      'Validity Status' as label,
      case when not_after is null or not_after < now() then 'alert' else 'ok' end as type
    from
      aws_acm_certificate
    where
      certificate_arn = $1;
  EOQ

  param "arn" {}
}

dashboard "aws_acm_certificate_detail" {
  title = "AWS ACM Certificate Detail"

  tags = merge(local.acm_common_tags, {
    type = "Detail"
  })

  input "certificate_arn" {
    title = "Select a certificate:"
    sql   = query.aws_acm_certificate_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      width = 2

      query = query.aws_acm_certificate_domain_name
      args = {
        arn = self.input.certificate_arn.value
      }
    }

    # Assessments
    card {
      width = 2

      query = query.aws_acm_certificate_transparency_logging_status
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

  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6

        sql = <<-EOQ
          select
            domain_name as "Domain Name",
            created_at as "Create Date",
            issuer as "Issuer",
            status as "Status",
            type as "Type",
            certificate_arn as "ARN",
            account_id as "Account ID"
          from
            aws_acm_certificate
          where
            certificate_arn = $1;
        EOQ

        param "arn" {}

        args = {
          arn = self.input.certificate_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          select
            tag ->> 'Key' as "Key",
            tag ->> 'Value' as "Value"
          from
            aws_acm_certificate,
            jsonb_array_elements(tags_src) as tag
          where
            certificate_arn = $1;
        EOQ

        param "arn" {}

        args = {
          arn = self.input.certificate_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "In Use By"
        sql   = <<-EOQ
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

        args = {
          arn = self.input.certificate_arn.value
        }
      }

    }

  }
}
