dashboard "aws_vpc_flow_log_configuration_dashboard" {
  title = "AWS VPC Flow Log Report"

  container {
    card {
      sql = <<-EOQ
        with vpc_logs as (
          select 
            vpc_id,
            case
              when vpc_id in (select resource_id from aws_vpc_flow_log) then 'Configured'
              else 'Not Configured'
            end as flow_logs_configured
          from 
            aws_vpc
        )
        select
          count(*) as value,
          'Flow Logs Not Configured' as label,
          case count(*) when 0 then 'ok' else 'alert' end as type
        from
          vpc_logs
        where
          flow_logs_configured = 'Not Configured';
      EOQ
      width = 2
    }
  }

  table {
    column "Account ID" {
      display = "none"
    }

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
        v.account_id = a.account_id;
    EOQ
  }
}
