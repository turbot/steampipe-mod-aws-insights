dashboard "rds_db_cluster_logging_report" {

  title         = "AWS RDS DB Cluster Logging Report"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_report_logging.md")

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Logging"
  })

  container {

    card {
      query = query.rds_db_cluster_count
      width = 3
    }

    card {
      query = query.rds_db_cluster_logging_disabled_count
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

    column "DB Cluster Identifier" {
      href = "${dashboard.rds_db_cluster_detail.url_path}?input.db_cluster_arn={{.ARN | @uri}}"
    }

    query = query.rds_db_cluster_logging_table
  }

}

query "rds_db_cluster_logging_table" {
  sql = <<-EOQ
    select
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
      c.db_cluster_identifier;
  EOQ
}
