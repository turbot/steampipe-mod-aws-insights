query "aws_rds_db_cluster_logging_disabled_count" {
  sql = <<-EOQ
    with logging_stat as(
      select
        db_cluster_identifier
      from
        aws_rds_db_cluster
      where
        ( engine like any (array ['mariadb', '%mysql']) and enabled_cloudwatch_logs_exports ?& array ['audit','error','general','slowquery'] ) or
        ( engine like any (array['%postgres%']) and enabled_cloudwatch_logs_exports ?& array ['postgresql','upgrade'] ) or
        ( engine like 'oracle%' and enabled_cloudwatch_logs_exports ?& array ['alert','audit', 'trace','listener'] ) or
        ( engine = 'sqlserver-ex' and enabled_cloudwatch_logs_exports ?& array ['error'] ) or
        ( engine like 'sqlserver%' and enabled_cloudwatch_logs_exports ?& array ['error','agent'] )
      )
  select
    count(*) as value,
    'Logging Disabled' as label,
    case count(*) when 0 then 'ok' else 'alert' end as type
  from
    aws_rds_db_cluster
  where
    db_cluster_identifier not in (select db_cluster_identifier from logging_stat)
  EOQ
}

dashboard "aws_rds_db_cluster_logging_dashboard" {

  title = "AWS RDS DB Cluster Logging Report"

  container {
    card {
      sql = query.aws_rds_db_cluster_logging_disabled_count.sql
      width = 2
    }
  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      select
        r.db_cluster_identifier as "DB Cluster",
        case
          when
            ( r.engine like any (array ['mariadb', '%mysql']) and r.enabled_cloudwatch_logs_exports ?& array ['audit','error','general','slowquery'] ) or ( r.engine like any (array['%postgres%']) and r.enabled_cloudwatch_logs_exports ?& array ['postgresql','upgrade'] ) or
            ( r.engine like 'oracle%' and r.enabled_cloudwatch_logs_exports ?& array ['alert','audit', 'trace','listener'] ) or
            ( r.engine = 'sqlserver-ex' and r.enabled_cloudwatch_logs_exports ?& array ['error'] ) or
            ( r.engine like 'sqlserver%' and r.enabled_cloudwatch_logs_exports ?& array ['error','agent'] )
          then  'Enabled' else null end as "Logging",
        r.engine as "Engine",
        r.enabled_cloudwatch_logs_exports as "Enabled CW Logs Exports",
        a.title as "Account",
        r.account_id as "Account ID",
        r.region as "Region",
        r.arn as "ARN"
      from
        aws_rds_db_cluster as r,
        aws_account as a
      where
        r.account_id = a.account_id
    EOQ
  }
}