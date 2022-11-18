dashboard "aws_s3_bucket_age_report" {

  title         = "AWS S3 Bucket Age Report"
  documentation = file("./dashboards/s3/docs/s3_bucket_report_age.md")

  tags = merge(local.s3_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.aws_s3_bucket_count
      width = 2
    }

    card {
      query = query.aws_s3_bucket_24_hours_count
      width = 2
      type  = "info"
    }

    card {
      query = query.aws_s3_bucket_30_days_count
      width = 2
      type  = "info"
    }

    card {
      query = query.aws_s3_bucket_30_90_days_count
      width = 2
      type  = "info"
    }

    card {
      query = query.aws_s3_bucket_90_365_days_count
      width = 2
      type  = "info"
    }

    card {
      query = query.aws_s3_bucket_1_year_count
      width = 2
      type  = "info"
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
      href = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.ARN | @uri}}"
    }

    query = query.aws_s3_bucket_age_table
  }

}

query "aws_s3_bucket_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_s3_bucket
    where
      creation_date > now() - '1 days' :: interval;
  EOQ
}

query "aws_s3_bucket_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_s3_bucket
    where
      creation_date between symmetric now() - '1 days' :: interval
      and now() - '30 days' :: interval;
  EOQ
}

query "aws_s3_bucket_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_s3_bucket
    where
      creation_date between symmetric now() - '30 days' :: interval
      and now() - '90 days' :: interval;
  EOQ
}

query "aws_s3_bucket_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_s3_bucket
    where
      creation_date between symmetric (now() - '90 days'::interval)
      and (now() - '365 days'::interval);
  EOQ
}

query "aws_s3_bucket_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_s3_bucket
    where
      creation_date <= now() - '1 year' :: interval;
  EOQ
}

query "aws_s3_bucket_age_table" {
  sql = <<-EOQ
    select
      b.name as "Name",
      now()::date - b.creation_date::date as "Age in Days",
      b.creation_date as "Create Time",
      a.title as "Account",
      b.account_id as "Account ID",
      b.region as "Region",
      b.arn as "ARN"
    from
      aws_s3_bucket as b,
      aws_account as a
    where
      b.account_id = a.account_id
    order by
      b.name;
  EOQ
}
