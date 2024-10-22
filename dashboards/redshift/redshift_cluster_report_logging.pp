dashboard "redshift_cluster_logging_report" {

  title         = "AWS Redshift Cluster Logging Report"
  documentation = file("./dashboards/redshift/docs/redshift_cluster_report_logging.md")

  tags = merge(local.redshift_common_tags, {
    type     = "Report"
    category = "Logging"
  })

  container {

    card {
      query = query.redshift_cluster_count
      width = 3
    }

    card {
      query = query.redshift_cluster_logging_status
      width = 3
    }

  }


  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Cluster Identifier" {
      href = "${dashboard.redshift_cluster_detail.url_path}?input.cluster_arn={{.ARN | @uri}}"
    }

    query = query.redshift_cluster_logging_table
  }

}

query "redshift_cluster_logging_status" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_redshift_cluster
    where
      logging_status ->> 'LoggingEnabled' = 'false'
  EOQ
}

query "redshift_cluster_logging_table" {
  sql = <<-EOQ
    select
      c.cluster_identifier as "Cluster Identifier",
      case when logging_status ->> 'LoggingEnabled' = 'true' then 'Enabled' else null end as "Logging",
      c.logging_status ->> 'BucketName' as "S3 Bucket Name",
      c.logging_status ->> 'S3KeyPrefix' as "S3 Key Prefix",
      c.logging_status ->> 'LastFailureTime' as "Last Failure Time",
      c.logging_status ->> 'LastSuccessfulDeliveryTime' as "Last Successful Delivery Time",
      a.title as "Account",
      c.account_id as "Account ID",
      c.region as "Region",
      c.arn as "ARN"
    from
      aws_redshift_cluster as c,
      aws_account as a
    where
      c.account_id = a.account_id
    order by
      c.cluster_identifier;
  EOQ
}
