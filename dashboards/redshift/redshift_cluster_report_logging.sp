dashboard "aws_redshift_cluster_logging_report" {

  title = "AWS Redshift Cluster Logging Report"

  container {

    card {
      sql = query.aws_redshift_cluster_count.sql
      width = 2
    }

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          'Logging Disabled' as label,
          case count(*) when 0 then 'ok' else 'alert' end as "type"
        from
          aws_redshift_cluster
        where
          logging_status ->> 'LoggingEnabled' = 'false'
      EOQ
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      select
        r.cluster_identifier as "Cluster",
        case when logging_status ->> 'LoggingEnabled' = 'true' then 'Enabled' else null end as "Logging",
        r.logging_status ->> 'BucketName' as "S3 Bucket Name",
        r.logging_status ->> 'S3KeyPrefix' as "S3 Key Prefix",
        r.logging_status ->> 'LastFailureTime' as "Last Failure Time",
        r.logging_status ->> 'LastSuccessfulDeliveryTime' as "Last Successful Delivery Time",
        a.title as "Account",
        r.account_id as "Account ID",
        r.region as "Region",
        r.arn as "ARN"
      from
        aws_redshift_cluster as r,
        aws_account as a
      where
        r.account_id = a.account_id
    EOQ
    
  }

}
