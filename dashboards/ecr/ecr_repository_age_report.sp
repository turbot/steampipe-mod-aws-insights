dashboard "ecr_repository_age_report" {

  title         = "AWS ECR Repository Age Report"
  documentation = file("./dashboards/ecr/docs/ecr_repository_report_age.md")

  tags = merge(local.ecr_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query =query.ecr_repository_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query =query.ecr_repository_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query =query.ecr_repository_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query =query.ecr_repository_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query =query.ecr_repository_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query =query.ecr_repository_1_year_count
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
      href = "${dashboard.ecr_repository_detail.url_path}?input.ecr_repository_arn={{.ARN | @uri}}"
    }
    query = query.ecr_repository_age_table
  }

}

query "ecr_repository_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_ecr_repository
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "ecr_repository_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_ecr_repository
    where
      created_at between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "ecr_repository_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_ecr_repository
    where
      created_at between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "ecr_repository_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_ecr_repository
    where
      created_at between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "ecr_repository_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_ecr_repository
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "ecr_repository_age_table" {
  sql = <<-EOQ
    select
      e.repository_name as "Name",
      now()::date - e.created_at::date as "Age in Days",
      e.created_at as "Created Time",
      a.title as "Account",
      e.account_id as "Account ID",
      e.region as "Region",
      e.arn as "ARN"
    from
      aws_ecr_repository as e,
      aws_account as a
    where
      e.account_id = a.account_id
    order by
      e.arn;
  EOQ
}