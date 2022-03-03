dashboard "aws_vpc_flow_log_configuration_report" {

  title = "AWS VPC Flow Log Report"

  tags = merge(local.vpc_common_tags, {
    type     = "Report"
    category = "Flow Logs Configuration"
  })

  container {

    card {
      sql   = query.aws_vpc_count.sql
      width = 2
    }

    card {
      sql = query.aws_vpc_no_flow_logs_count.sql
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = query.aws_vpc_flow_log_configuration_table.sql
  }

}

query "aws_vpc_flow_log_configuration_table" {
  sql = <<-EOQ
    select
      v.tags ->> 'Name' as "Name",
      v.vpc_id as "VPC",
      case
        when vpc_id in (select resource_id from aws_vpc_flow_log) then 'Configured'
        else 'Not Configured'
      end as "Flow Log Status",
      a.title as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.arn as "ARN"
    from
      aws_vpc as v,
      aws_account as a
    where
      v.account_id = a.account_id
    order by
      v.tags ->> 'Name',
      v.vpc_id;
  EOQ
}