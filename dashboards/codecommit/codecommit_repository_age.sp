dashboard "aws_codecommit_repository_age_report" {

  title         = "AWS Codecommit Age Report"
  documentation = file("./dashboards/codecommit/docs/codecommit_repository_report_age.md")

  tags = merge(local.codecommit_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.aws_codecommit_repository_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_codecommit_repository_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_codecommit_repository_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_codecommit_repository_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.aws_codecommit_repository_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.aws_codecommit_repository_1_year_count
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.aws_codecommit_repository_detail.url_path}?input.codecommit_repository_arn={{.ARN | @uri}}"
    }
    query = query.aws_codecommit_repository_age_table
  }

}

query "aws_codecommit_repository_24_hours_count" {
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

query "aws_codecommit_repository_30_days_count" {
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

query "aws_codecommit_repository_30_90_days_count" {
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

query "aws_codecommit_repository_90_365_days_count" {
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

query "aws_codecommit_repository_1_year_count" {
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

query "aws_codecommit_repository_age_table" {
  sql = <<-EOQ
    select
      p.repository_name as "Name",
      now()::date - p.creation_date::date as "Age in Days",
      p.creation_date as "creation_date Time",
      p.title as "Account",
      p.repository_id as "Account ID",
      p.region as "Region",
      p.arn as "ARN"
    from
      aws_codecommit_repository as p,
      aws_account as a
    where
      p.account_id = a.account_id
    order by
      p.arn;
  EOQ
}