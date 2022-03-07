dashboard "aws_rds_db_cluster_logging_report" {

  title = "AWS RDS DB Cluster Logging Report"

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Logging"
  })

  container {

    card {
      sql   = query.aws_rds_db_cluster_count.sql
      width = 2
    }

    card {
      sql = query.aws_rds_db_cluster_logging_status.sql
      width = 2
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    sql = query.aws_rds_db_cluster_logging_table.sql
  }

}

query "aws_rds_db_cluster_logging_table" {
  sql = <<-EOQ
    select
      c.resource_id as "Resource ID",
      c.db_cluster_identifier as "DB Cluster Identifier",
      case
        when
          ( c.engine like any (array ['mariadb', '%mysql']) and c.enabled_cloudwatch_logs_exports ?& array ['audit','error','general','slowquery'] ) or ( c.engine like any (array['%postgres%']) and c.enabled_cloudwatch_logs_exports ?& array ['postgresql','upgrade'] ) or
          ( c.engine like 'oracle%' and c.enabled_cloudwatch_logs_exports ?& array ['alert','audit', 'trace','listener'] ) or
          ( c.engine = 'sqlserver-ex' and c.enabled_cloudwatch_logs_exports ?& array ['error'] ) or
          ( c.engine like 'sqlserver%' and c.enabled_cloudwatch_logs_exports ?& array ['error','agent'] )
        then  'Enabled' else null end as "Logging",
      c.engine as "Engine",
      c.enabled_cloudwatch_logs_exports as "Enabled CW Logs Exports",
      a.title as "Account",
      c.account_id as "Account ID",
      c.region as "Region",
      c.arn as "ARN"
    from
      aws_rds_db_cluster as c,
      aws_account as a
    where
      c.account_id = a.account_id
    order by
      c.resource_id;
  EOQ
}
