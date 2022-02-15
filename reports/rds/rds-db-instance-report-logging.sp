query "aws_rds_db_instance_logging_disabled_count" {
  sql = <<-EOQ
    with logging_stat as(
      select
        db_instance_identifier
      from
        aws_rds_db_instance
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
    case count(*) when 0 then 'ok' else 'alert' end as style
  from
    aws_rds_db_instance
  where
    db_instance_identifier not in (select db_instance_identifier from logging_stat)
  EOQ
}

report "aws_rds_db_instance_logging_report" {

  title = "AWS RDS DB Instance Logging Report"

  container {
    card {
      sql = query.aws_rds_db_instance_logging_disabled_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        db_instance_identifier as "DB Instance",
        case
          when
            ( engine like any (array ['mariadb', '%mysql']) and enabled_cloudwatch_logs_exports ?& array ['audit','error','general','slowquery'] ) or ( engine like any (array['%postgres%']) and enabled_cloudwatch_logs_exports ?& array ['postgresql','upgrade'] ) or
            ( engine like 'oracle%' and enabled_cloudwatch_logs_exports ?& array ['alert','audit', 'trace','listener'] ) or
            ( engine = 'sqlserver-ex' and enabled_cloudwatch_logs_exports ?& array ['error'] ) or
            ( engine like 'sqlserver%' and enabled_cloudwatch_logs_exports ?& array ['error','agent'] )
          then  'Enabled' else null end as "Logging",
        engine as "Engine",
        enabled_cloudwatch_logs_exports as "Enabled CW Logs Exports",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_rds_db_instance
    EOQ
  }
}
