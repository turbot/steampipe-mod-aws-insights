dashboard "acm_certificate_dashboard" {

  title         = "AWS ACM Certificate Dashboard"
  documentation = file("./dashboards/acm/docs/acm_certificate_dashboard.md")

  tags = merge(local.acm_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.acm_certificate_count
      width = 2
    }

    card {
      query = query.acm_certificate_revoked_count
      width = 2
    }

    # Assessments
    card {
      query = query.acm_certificate_renewal_eligibility_ineligible
      width = 2
    }

    card {
      query = query.acm_certificate_invalid
      width = 2
    }

    card {
      query = query.acm_certificate_transparency_logging_disabled
      width = 2
    }
  }

  container {

    title = "Assessments"

    chart {
      title = "Certificate Validity"
      query = query.acm_certificate_by_validity
      type  = "donut"
      width = 3

      series "count" {
        point "valid" {
          color = "ok"
        }
        point "invalid" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Transparency Logging Status"
      query = query.acm_certificate_by_transparency_logging_preference
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Certificates by Account"
      query = query.acm_certificate_by_account
      type  = "column"
      width = 3
    }

    chart {
      title = "Certificates by Region"
      query = query.acm_certificate_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Certificates by Type"
      query = query.acm_certificate_by_type
      type  = "column"
      width = 3
    }

    chart {
      title = "Certificates by Age"
      query = query.acm_certificate_by_age
      type  = "column"
      width = 3
    }
  }
}

# Card Queries

query "acm_certificate_count" {
  sql = <<-EOQ
    select count(*) as "Certificates" from aws_acm_certificate;
  EOQ
}

query "acm_certificate_revoked_count" {
  sql = <<-EOQ
    select count(*) as "Revoked Certificates" from aws_acm_certificate where revoked_at is not null;
  EOQ
}

query "acm_certificate_renewal_eligibility_ineligible" {
  sql = <<-EOQ
    select
      count(*) as "Ineligible for Renewal"
    from
      aws_acm_certificate
    where
      renewal_eligibility = 'INELIGIBLE';
  EOQ
}

query "acm_certificate_invalid" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Invalid Certificates' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_acm_certificate
    where
      not_after is null or not_after < now();
  EOQ
}

query "acm_certificate_transparency_logging_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Transparency Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_acm_certificate
    where
      certificate_transparency_logging_preference = 'DISABLED';
  EOQ
}

# Assessment Queries

query "acm_certificate_by_validity" {
  sql = <<-EOQ
    select
      validity,
      count(*)
    from (
      select not_after,
        case when not_after is null or not_after < now() then
          'invalid'
        else
          'valid'
        end validity
      from
        aws_acm_certificate) as t
    group by
      validity
    order by
      validity;
  EOQ
}

query "acm_certificate_by_transparency_logging_preference" {
  sql = <<-EOQ
    select
      certificate_transparency_logging_preference_status,
      count(*)
    from (
      select certificate_transparency_logging_preference,
        case when certificate_transparency_logging_preference = 'ENABLED' then
          'enabled'
        else
          'disabled'
        end certificate_transparency_logging_preference_status
      from
        aws_acm_certificate) as t
    group by
      certificate_transparency_logging_preference_status
    order by
      certificate_transparency_logging_preference_status desc;
  EOQ
}

# Analysis Queries

query "acm_certificate_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(v.*) as "Certificates"
    from
      aws_acm_certificate as v,
      aws_account as a
    where
      a.account_id = v.account_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "acm_certificate_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Certificates" from aws_acm_certificate group by region order by region;
  EOQ
}

query "acm_certificate_by_type" {
  sql = <<-EOQ
    select
      type as "Type",
      count(type) as "Certificates"
    from
      aws_acm_certificate
    group by
      type
    order by
      type;
  EOQ
}

query "acm_certificate_by_age" {
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
