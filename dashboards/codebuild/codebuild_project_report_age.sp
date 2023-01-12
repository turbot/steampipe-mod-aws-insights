dashboard "codebuild_project_age_report" {

  title         = "AWS CodeBuild Project Age Report"
  documentation = file("./dashboards/codebuild/docs/codebuild_project_report_age.md")

  tags = merge(local.codebuild_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.codebuild_project_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.codebuild_project_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.codebuild_project_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.codebuild_project_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.codebuild_project_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.codebuild_project_1_year_count
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
      href = "${dashboard.codebuild_project_detail.url_path}?input.codebuild_project_arn={{.ARN | @uri}}"
    }
    query = query.codebuild_project_age_table
  }

}

query "codebuild_project_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_codebuild_project
    where
      created > now() - '1 days' :: interval;
  EOQ
}

query "codebuild_project_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_codebuild_project
    where
      created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "codebuild_project_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_codebuild_project
    where
      created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "codebuild_project_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_codebuild_project
    where
      created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "codebuild_project_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_codebuild_project
    where
      created <= now() - '1 year' :: interval;
  EOQ
}

query "codebuild_project_age_table" {
  sql = <<-EOQ
    select
      p.name as "Name",
      now()::date - p.created::date as "Age in Days",
      p.created as "Created Time",
      a.title as "Account",
      p.account_id as "Account ID",
      p.region as "Region",
      p.arn as "ARN"
    from
      aws_codebuild_project as p,
      aws_account as a
    where
      p.account_id = a.account_id
    order by
      p.arn;
  EOQ
}
