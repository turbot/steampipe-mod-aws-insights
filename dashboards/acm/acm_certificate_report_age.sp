dashboard "acm_certificate_age_report" {

  title = "AWS ACM Certificate Age Report"

  tags = merge(local.acm_common_tags, {
    type     = "Report"
    category = "Age"
  })

   container {

    card {
      sql   = query.aws_acm_certificate_count.sql
      width = 2
    }

    card {
      type = "info"
      sql = query.aws_acm_certificate_24_hours_count.sql
      width = 2
    }

    card {
      type = "info"
      sql = query.aws_acm_certificate_30_days_count.sql
      width = 2
    }

    card {
      type = "info"
      sql = query.aws_acm_certificate_30_90_days_count.sql
      width = 2
    }

    card {
      type = "info"
      sql = query.aws_acm_certificate_90_365_days_count.sql
      width = 2
    }

    card {
      type = "info"
      sql = query.aws_acm_certificate_1_year_count.sql
      width = 2
    }

  }

  container {

    table {
      column "Account ID" {
        display = "none"
      }

      sql = query.aws_acm_certificate_age_table.sql
    }

  }

}


query "aws_acm_certificate_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_acm_certificate
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "aws_acm_certificate_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_acm_certificate
    where
      created_at between symmetric now() - '1 days' :: interval
      and now() - '30 days' :: interval;
  EOQ
}

query "aws_acm_certificate_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_acm_certificate
    where
      created_at between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "aws_acm_certificate_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_acm_certificate
    where
      created_at between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "aws_acm_certificate_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_acm_certificate
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "aws_acm_certificate_age_table" {
  sql = <<-EOQ
    select
      c.tags ->> 'Name' as "Name",
      c.domain_name as "Domain Name",
      c.title as "ID",
      now()::date - c.created_at::date as "Age in Days",
      c.created_at as "Create Time",
      c.not_after as "Expiry Time",
      c.status as "Status",
      a.title as "Account",
      c.account_id as "Account ID",
      c.region as "Region",
      c.certificate_arn as "ARN"
    from
      aws_acm_certificate as c,
      aws_account as a
    where
      c.account_id = a.account_id
    order by
      c.tags ->> 'Name',
      c.domain_name;
  EOQ
}