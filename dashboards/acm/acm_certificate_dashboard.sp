query "aws_acm_certificate_count" {
  sql = <<-EOQ
    select count(*) as "Certificates" from aws_acm_certificate
  EOQ
}

query "aws_acm_certificate_revoked_count" {
  sql = <<-EOQ
    select count(*) as "Revoked Certificates" from aws_acm_certificate where revoked_at is not null
  EOQ
}

query "aws_acm_certificate_renewal_eligibility_ineligible" {
  sql = <<-EOQ
    with renewal_eligibility_ineligible as (
      select
        certificate_arn
      from
        aws_acm_certificate
      where
        renewal_eligibility = 'INELIGIBLE'
    )
    select
      count(*) as value,
      'Ineligible for Renewal' as label
      -- case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      renewal_eligibility_ineligible
  EOQ
}

query "aws_acm_certificate_invalid" {
  sql = <<-EOQ
    with certificate_invalid as (
      select
        certificate_arn
      from
        aws_acm_certificate
      where
        not_after is null or not_after < now()
    )
    select
      count(*) as value,
      'Invalid Certificates' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      certificate_invalid
  EOQ
}

query "aws_acm_certificate_in_use_by" {
  sql = <<-EOQ
    with in_use_by as (
      select
        certificate_arn
      from
        aws_acm_certificate
      where
        jsonb_array_length(in_use_by) > 0
    )
    select
      count(*) as value,
      'Certificates In Use' as label,
      case count(*) when 0 then 'alert' else 'ok' end as "type"
    from
      in_use_by
  EOQ
}

query "aws_acm_certificate_transparency_logging_disabled" {
  sql = <<-EOQ
    with transparency_logging_disabled as (
      select
        certificate_arn
      from
        aws_acm_certificate
      where
        certificate_transparency_logging_preference = 'DISABLED'
    )
    select
      count(*) as value,
      'Disabled Transparency Logging' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      transparency_logging_disabled
  EOQ
}

# Assessments
query "aws_acm_certificate_by_status" {
  sql = <<-EOQ
    select
      status as "status",
      count(status) as "certificates"
    from
      aws_acm_certificate
    group by
      status
    order by
      status
  EOQ
}

query "aws_acm_certificate_by_eligibility" {
  sql = <<-EOQ
    select
      renewal_eligibility as "eligibility",
      count(renewal_eligibility) as "certificates"
    from
      aws_acm_certificate
    group by
      renewal_eligibility
    order by
      renewal_eligibility
  EOQ
}

query "aws_acm_certificate_by_validity" {
  sql = <<-EOQ
    select
      validity,
      count(*)
    from (
      select not_after,
        case when not_after is null or not_after < now() then
          'Invalid'
        else
          'Valid'
        end validity
      from
        aws_acm_certificate) as t
    group by
      validity
    order by
      validity
  EOQ
}

query "aws_acm_certificate_by_use" {
  sql = <<-EOQ
    select
       usage,
      count(*)
    from (
      select
        in_use_by,
        case when jsonb_array_length(in_use_by) > 0 then
          'In-Use'
        else
          'Not In-Use'
        end usage
      from
        aws_acm_certificate) as t
    group by
      usage
    order by
      usage
  EOQ
}

query "aws_acm_certificate_by_transparency_logging_preference" {
  sql = <<-EOQ
    select
      certificate_transparency_logging_preference as "preference",
      count(certificate_transparency_logging_preference) as "certificates"
    from
      aws_acm_certificate
    group by
      certificate_transparency_logging_preference
    order by
      certificate_transparency_logging_preference
  EOQ
}

# Analysis
query "aws_acm_certificate_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(v.*) as "certificates"
    from
      aws_acm_certificate as v,
      aws_account as a
    where
      a.account_id = v.account_id
    group by
      account
    order by
      account
  EOQ
}

query "aws_acm_certificate_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "certificates" from aws_acm_certificate group by region order by region
  EOQ
}

query "aws_acm_certificate_by_type" {
  sql = <<-EOQ
    select
      type as "type",
      count(type) as "certificates"
    from
      aws_acm_certificate
    group by
      type
    order by
      type
  EOQ
}

query "aws_acm_certificate_by_age" {
  sql = <<-EOQ
    with certificates as (
      select
        title,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        aws_acm_certificate
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_at)
                from certificates)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    certificates_by_month as (
      select
        creation_month,
        count(*)
      from
        certificates
      group by
        creation_month
    )
    select
      months.month,
      certificates_by_month.count
    from
      months
      left join certificates_by_month on months.month = certificates_by_month.creation_month
    order by
      months.month;
  EOQ
}

dashboard "aws_acm_certificate_dashboard" {

  title = "AWS ACM Certificate Dashboard"

  container {

    card {
      sql   = query.aws_acm_certificate_count.sql
      width = 2
    }

    card {
      sql   = query.aws_acm_certificate_revoked_count.sql
      width = 2
    }

    card {
      sql   = query.aws_acm_certificate_renewal_eligibility_ineligible.sql
      width = 2
    }

    card {
      sql   = query.aws_acm_certificate_invalid.sql
      width = 2
    }

    card {
      sql   = query.aws_acm_certificate_in_use_by.sql
      width = 2
    }

    card {
      sql   = query.aws_acm_certificate_transparency_logging_disabled.sql
      width = 2
    }
  }

  container {
    title = "Assessments"

    chart {
      title = "Certificate Status"
      sql   = query.aws_acm_certificate_by_status.sql
      type  = "donut"
      width = 2
    }

    chart {
      title = "Certificate Renewal Eligibilty"
      sql   = query.aws_acm_certificate_by_eligibility.sql
      type  = "donut"
      width = 2
    }

    chart {
      title = "Certificate Validity"
      sql   = query.aws_acm_certificate_by_validity.sql
      type  = "donut"
      width = 2
    }

    chart {
      title = "Certificate Usage Status"
      sql   = query.aws_acm_certificate_by_use.sql
      type  = "donut"
      width = 2
    }

    chart {
      title = "Certificate Transparency Logging Status"
      sql   = query.aws_acm_certificate_by_transparency_logging_preference.sql
      type  = "donut"
      width = 2
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Certificates by Account"
      sql   = query.aws_acm_certificate_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Certificates by Region"
      sql   = query.aws_acm_certificate_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Certificates by Type"
      sql   = query.aws_acm_certificate_by_type.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Certificates by Age"
      sql   = query.aws_acm_certificate_by_age.sql
      type  = "column"
      width = 3
    }
  }

}