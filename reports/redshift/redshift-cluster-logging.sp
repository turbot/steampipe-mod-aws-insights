query "aws_redshift_cluster_logging_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_redshift_cluster
    where
      logging_status ->> 'LoggingEnabled' = 'false'
  EOQ
}

report "aws_redshift_cluster_logging_report" {

  title = "AWS Redshift Cluster Logging Report"

  container {

    card {
      sql = query.aws_redshift_cluster_logging_disabled_count.sql
      width = 2
    }

  }

  table {
    sql = <<-EOQ
      select
        cluster_identifier as "Cluster",
        case when logging_status ->> 'LoggingEnabled' = 'true' then 'Enabled' else null end as "Logging",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_redshift_cluster
    EOQ
  }

}



    #   select
    #     cluster_identifier as "Cluster",
    #     case when logging_status ->> 'LoggingEnabled' = 'true' then 'Enabled' else null end as "Logging",
    #     account_id as "Account",
    #     region as "Region",
    #     arn as "ARN"
    #   from
    #     aws_redshift_cluster