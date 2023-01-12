dashboard "codecommit_repository_age_report" {

  title         = "AWS CodeCommit Repository Age Report"
  documentation = file("./dashboards/codecommit/docs/codecommit_repository_report_age.md")

  tags = merge(local.codecommit_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.codecommit_repository_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.codecommit_repository_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.codecommit_repository_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.codecommit_repository_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.codecommit_repository_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.codecommit_repository_1_year_count
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Repository ID" {
      href = "${dashboard.codecommit_repository_detail.url_path}?input.codecommit_repository_arn={{.ARN | @uri}}"
    }
    query = query.codecommit_repository_age_table
  }

}

query "codecommit_repository_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_codecommit_repository
    where
      creation_date > now() - '1 days' :: interval;
  EOQ
}

query "codecommit_repository_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_codecommit_repository
    where
      creation_date between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "codecommit_repository_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_codecommit_repository
    where
      creation_date between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "codecommit_repository_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_codecommit_repository
    where
      creation_date between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "codecommit_repository_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_codecommit_repository
    where
      creation_date <= now() - '1 year' :: interval;
  EOQ
}

query "codecommit_repository_age_table" {
  sql = <<-EOQ
    select
      r.repository_id as "Repository ID",
      r.repository_name as "Repository Name",
      now()::date - r.creation_date::date as "Age in Days",
      r.creation_date as "Creation Time",
      a.title as "Account",
      r.account_id as "Account ID",
      r.region as "Region",
      r.arn as "ARN"
    from
      aws_codecommit_repository as r,
      aws_account as a
    where
      r.account_id = a.account_id
    order by
      r.repository_id;
  EOQ
}
