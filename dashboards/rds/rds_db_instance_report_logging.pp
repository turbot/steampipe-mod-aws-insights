dashboard "rds_db_instance_logging_report" {

  title         = "AWS RDS DB Instance Logging Report"
  documentation = file("./dashboards/rds/docs/rds_db_instance_report_logging.md")

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Logging"
  })

  container {

    card {
      query = query.rds_db_instance_count
      width = 3
    }

    card {
      query = query.rds_db_instance_logging_disabled_count
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

    column "DB Instance Identifier" {
      href = "${dashboard.rds_db_instance_detail.url_path}?input.db_instance_arn={{.ARN | @uri}}"
    }

    query = query.rds_db_instance_logging_table
  }

}

query "rds_db_instance_logging_table" {
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
      i.account_id = a.account_id
    order by
      i.db_instance_identifier;
  EOQ
}
