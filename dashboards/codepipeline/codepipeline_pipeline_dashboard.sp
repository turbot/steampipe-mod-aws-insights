dashboard "codepipeline_pipeline_dashboard" {

  title         = "AWS CodePipeline Pipeline Dashboard"
  documentation = file("./dashboards/codepipeline/docs/codepipeline_pipeline_dashboard.md")

  tags = merge(local.codepipeline_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query   = query.codepipeline_pipeline_count
      width = 2
    }

    card {
      query   = query.codepipeline_pipeline_unencrypted_count
      width = 2
    }
  }

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Encryption status"
      query   = query.codepipeline_pipeline_encryption_status
      type  = "donut"
      width = 4

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
      title = "Pipelines by Account"
      query   = query.codepipeline_pipeline_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Pipelines by Region"
      query   = query.codepipeline_pipeline_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Pipelines by Age"
      query   = query.codepipeline_pipeline_by_creation_month
      width = 4
    }

  }

}

# Card Queries

query "codepipeline_pipeline_count" {
  sql = <<-EOQ
    select
      count(*) as "Pipelines"
    from
      aws_codepipeline_pipeline;
  EOQ
}

query "codepipeline_pipeline_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case
        when count(*) > 0 then 'alert' else 'ok' end as "type"
    from
      aws_codepipeline_pipeline
    where
      encryption_key is null;
  EOQ
}

// # Assessment Queries

query "codepipeline_pipeline_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select encryption_key,
        case when encryption_key is not null then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_codepipeline_pipeline) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

# Analysis Queries

query "codepipeline_pipeline_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(c.*) as "pipelines"
    from
      aws_codepipeline_pipeline as c,
      aws_account as a
    where
      a.account_id = c.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "codepipeline_pipeline_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "pipelines"
    from
      aws_codepipeline_pipeline
    group by
      region
    order by
      region;
  EOQ
}

query "codepipeline_pipeline_by_creation_month" {
  sql = <<-EOQ
    with clusters as (
      select
        title,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        aws_codepipeline_pipeline
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
                from clusters)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    clusters_by_month as (
      select
        creation_month,
        count(*)
      from
        clusters
      group by
        creation_month
    )
    select
      months.month,
      clusters_by_month.count
    from
      months
      left join clusters_by_month on months.month = clusters_by_month.creation_month
    order by
      months.month;
  EOQ
}
