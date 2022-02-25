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
    case count(*) when 0 then 'ok' else 'alert' end as type
  from
    aws_rds_db_instance
  where
    db_instance_identifier not in (select db_instance_identifier from logging_stat);
  EOQ
}

dashboard "aws_rds_db_instance_logging_dashboard" {

  title = "AWS RDS DB Instance Logging Report"

  container {

    card {
      sql   = query.aws_rds_db_instance_count.sql
      width = 2
    }

    card {
      sql = query.aws_rds_db_instance_logging_disabled_count.sql
      width = 2
    }
  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      select
        i.db_instance_identifier as "DB Instance Identifier",
        case
          when
            ( i.engine like any (array ['mariadb', '%mysql']) and i.enabled_cloudwatch_logs_exports ?& array ['audit','error','general','slowquery'] ) or ( i.engine like any (array['%postgres%']) and i.enabled_cloudwatch_logs_exports ?& array ['postgresql','upgrade'] ) or
            ( i.engine like 'oracle%' and i.enabled_cloudwatch_logs_exports ?& array ['alert','audit', 'trace','listener'] ) or
            ( i.engine = 'sqlserver-ex' and i.enabled_cloudwatch_logs_exports ?& array ['error'] ) or
            ( i.engine like 'sqlserver%' and i.enabled_cloudwatch_logs_exports ?& array ['error','agent'] )
          then  'Enabled' else null end as "Logging",
        i.engine as "Engine",
        i.enabled_cloudwatch_logs_exports as "Enabled CW Logs Exports",
        a.title as "Account",
        i.account_id as "Account ID",
        i.region as "Region",
        i.arn as "ARN"
      from
        aws_rds_db_instance as i,
        aws_account as a
      where
        i.account_id = a.account_id;
    EOQ

  }

}
