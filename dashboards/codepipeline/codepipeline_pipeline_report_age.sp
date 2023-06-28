dashboard "codepipeline_pipeline_age_report" {

  title         = "AWS CodePipeline Pipeline Age Report"
  documentation = file("./dashboards/codepipeline/docs/codepipeline_pipeline_report_age.md")


  tags = merge(local.codepipeline_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.codepipeline_pipeline_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.codepipeline_pipeline_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.codepipeline_pipeline_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.codepipeline_pipeline_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.codepipeline_pipeline_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.codepipeline_pipeline_1_year_count
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
      href = "${dashboard.codepipeline_pipeline_detail.url_path}?input.pipeline_arn={{.ARN | @uri}}"
    }

    query = query.codepipeline_pipeline_age_table
  }

}

query "codepipeline_pipeline_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_codepipeline_pipeline
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "codepipeline_pipeline_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_codepipeline_pipeline
    where
      created_at between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "codepipeline_pipeline_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_codepipeline_pipeline
    where
      created_at between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "codepipeline_pipeline_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_codepipeline_pipeline
    where
      created_at between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "codepipeline_pipeline_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_codepipeline_pipeline
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "codepipeline_pipeline_age_table" {
  sql = <<-EOQ
    select
      c.name as "Name",
      now()::date - c.created_at::date as "Age in Days",
      c.created_at as "Create Time",
      a.title as "Account",
      c.account_id as "Account ID",
      c.region as "Region",
      c.arn as "ARN"
    from
      aws_codepipeline_pipeline as c,
      aws_account as a
    where
      c.account_id = a.account_id
    order by
      c.created_at,
      c.name;
  EOQ
}
