query "aws_acm_certificate_count" {
  sql = <<-EOQ
    select count(*) as "Certificates" from aws_acm_certificate;
  EOQ
}

query "aws_acm_certificate_revoked_count" {
  sql = <<-EOQ
    select count(*) as "Revoked Certificates" from aws_acm_certificate where revoked_at is not null;
  EOQ
}

query "aws_acm_certificate_renewal_eligibility_ineligible" {
  sql = <<-EOQ
    select
      count(*) as "Ineligible for Renewal"
    from
      aws_acm_certificate
    where
      renewal_eligibility = 'INELIGIBLE';
  EOQ
}

query "aws_acm_certificate_invalid" {
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

query "aws_acm_certificate_in_use_by" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Certificates In Use' as label,
      case count(*) when 0 then 'alert' else 'ok' end as type
    from
      aws_acm_certificate
    where
      jsonb_array_length(in_use_by) > 0;
  EOQ
}

query "aws_acm_certificate_transparency_logging_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_acm_certificate
    where
      certificate_transparency_logging_preference = 'DISABLED';
  EOQ
}

# Assessments
query "aws_acm_certificate_by_status" {
  sql = <<-EOQ
    select
      lower(status),
      count(status)
    from
      aws_acm_certificate
    group by
      status
    order by
      status;
  EOQ
}

query "aws_acm_certificate_by_eligibility" {
  sql = <<-EOQ
    select
      lower(renewal_eligibility),
      count(renewal_eligibility) as "Certificates"
    from
      aws_acm_certificate
    group by
      renewal_eligibility
    order by
      renewal_eligibility;
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

query "aws_acm_certificate_by_use" {
  sql = <<-EOQ
    select
       usage,
      count(*)
    from (
      select
        in_use_by,
        case when jsonb_array_length(in_use_by) > 0 then
          'in_use'
        else
          'not_in_use'
        end usage
      from
        aws_acm_certificate) as t
    group by
      usage
    order by
      usage;
  EOQ
}

query "aws_acm_certificate_by_transparency_logging_preference" {
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

# Analysis
query "aws_acm_certificate_by_account" {
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

query "aws_acm_certificate_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Certificates" from aws_acm_certificate group by region order by region;
  EOQ
}

query "aws_acm_certificate_by_type" {
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

  tags = merge(local.acm_common_tags, {
    type = "Dashboard"
  })

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

      series "count" {
        point "issued" {
          color = "green"
        }
        point "failed" {
          color = "red"
        }
      }
    }

    chart {
      title = "Renewal Eligibilty"
      sql   = query.aws_acm_certificate_by_eligibility.sql
      type  = "donut"
      width = 2
    }

    chart {
      title = "Certificate Validity"
      sql   = query.aws_acm_certificate_by_validity.sql
      type  = "donut"
      width = 2

      series "count" {
        point "valid" {
          color = "green"
        }
        point "invalid" {
          color = "red"
        }
      }
    }

    chart {
      title = "Certificate Usage Status"
      sql   = query.aws_acm_certificate_by_use.sql
      type  = "donut"
      width = 2

      series "count" {
        point "in_use" {
          color = "green"
        }
        point "not_in_use" {
          color = "red"
        }
      }
    }

    chart {
      title = "Logging Status"
      sql   = query.aws_acm_certificate_by_transparency_logging_preference.sql
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "green"
        }
        point "disabled" {
          color = "red"
        }
      }
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
