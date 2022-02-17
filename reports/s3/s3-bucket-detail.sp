report aws_s3_bucket_detail {
  title = "AWS S3 Bucket Detail"

  input {
    title = "Bucket"
    sql   = <<-EOQ
      select
        name
      from
        aws_s3_bucket
    EOQ
    width = 2
  }
  container {

     # Analysis
    card {
      #title = "Size"
      sql   = query.aws_s3_bucket_access_points_count.sql
      width = 2
    }

  }

  container {
    title  = "Analysis"

    container {

      container {
        width = 6

        table {
          title = "Overview"

          sql   = <<-EOQ
            select
              name,
              creation_date,
              logging,
              title,
              region,
              account_id,
              arn
            from
              aws_s3_bucket
                where
              name = 'aab-saea1-1t8oayt4mlkjv'
          EOQ
        }

        table {
          title = "Tags"

          sql   = <<-EOQ
            select
              tag ->> 'Key' as "Key",
              tag ->> 'Value' as "Value"
            from
              aws_s3_bucket,
              jsonb_array_elements(tags_src) as tag
            where
              name = 'aab-saea1-1t8oayt4mlkjv'
          EOQ
        }
      }

    }

  }

}

  query "aws_s3_bucket_access_points_count" {
    sql = <<-EOQ
      select
        'Access Points' as label,
        count(*) as value,
        case when count(*) > 0 then 'ok' else 'alert' end as type
      from
        aws_s3_access_point
      where
        bucket_name = 'aab-saea1-1t8oayt4mlkjv'
  EOQ
  }
