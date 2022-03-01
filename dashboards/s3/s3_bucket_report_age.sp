dashboard "aws_s3_bucket_age_report" {

  title = "AWS S3 Bucket Age Report"

  tags = merge(local.s3_common_tags, {
    type     = "Report"
    category = "Age"
  })

    container {

    # Analysis
    card {
      sql   = query.aws_s3_bucket_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          aws_s3_bucket
        where
          creation_date > now() - '1 days' :: interval;
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '1-30 Days' as label
        from
          aws_s3_bucket
        where
          creation_date between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '30-90 Days' as label
        from
          aws_s3_bucket
        where
          creation_date between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '90-365 Days' as label
        from
          aws_s3_bucket
        where
          creation_date between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '> 1 Year' as label
        from
          aws_s3_bucket
        where
          creation_date <= now() - '1 year' :: interval;
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
          v.name as "Name",
          --date_trunc('day',age(now(),v.creation_date))::text as "Age",
          now()::date - v.creation_date::date as "Age in Days",
          v.creation_date as "Create Time",
          a.title as "Account",
          v.account_id as "Account ID",
          v.region as "Region",
          v.arn as "ARN"
        from
          aws_s3_bucket as v,
          aws_account as a
        where
          v.account_id = a.account_id
        order by
          v.creation_date,
          v.title;
      EOQ

    }

  }

}

/*

select
  'value 1' as value,
  'value 2' as value

*/