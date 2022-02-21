dashboard "acm_certificate_age_report" {

  title = "AWS ACM Certificate Age Report"

   container {

    # Analysis
    card {
      sql   = query.aws_acm_certificate_count.sql
      width = 2
    }

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          aws_acm_certificate
        where
          created_at > now() - '1 days' :: interval
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          '1-30 Days' as label
        from
          aws_acm_certificate
        where
          created_at between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          '30-90 Days' as label
        from
          aws_acm_certificate
        where
          created_at between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          '90-365 Days' as label
        from
          aws_acm_certificate
        where
          created_at between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          '> 1 Year' as label
        from
          aws_acm_certificate
        where
          created_at <= now() - '1 year' :: interval
      EOQ
      width = 2
      type = "info"
    }
  }

  container {

    table {

      column "Account ID" {
        display = "none"
      }

      sql = <<-EOQ
        select
          v.tags ->> 'Name' as "Name",
          v.title as "ID",
          -- date_trunc('day',age(now(),v.created_at))::text as "Age",
          now()::date - v.created_at::date as "Age in Days",
          v.created_at as "Create Time",
          v.status as "Status",
          -- a.account_aliases  ->> 0 as "Account Name",
          a.title as "Account",
          v.account_id as "Account ID",
          v.region as "Region",
          v.certificate_arn as "ARN"
        from
          aws_acm_certificate as v,
          aws_account as a
        where
          v.account_id = a.account_id
        order by
          v.created_at,
          v.title
      EOQ
    }

  }

}
