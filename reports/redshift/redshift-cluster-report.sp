query "aws_redshift_cluster_public_access" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Is Publicly Accessible' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      aws_redshift_cluster
    where
      publicly_accessible
  EOQ
}

report "aws_redshift_cluster_public_access" {

  title = "AWS Redshift Cluster Report"

  container {

    card {
      sql = query.aws_redshift_cluster_public_access.sql
      width = 2
    }

  }

#   table {
#     sql = <<-EOQ
#       select
#         cluster_identifier as "Cluster",
#         case when logging_status ->> 'LoggingEnabled' = 'true' then 'Enabled' else null end as "Logging",
#         account_id as "Account",
#         region as "Region",
#         arn as "ARN"
#       from
#         aws_redshift_cluster
#     EOQ
#   }

}