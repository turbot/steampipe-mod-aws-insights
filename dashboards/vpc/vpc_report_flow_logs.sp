dashboard "vpc_flow_logs_report" {

  title         = "AWS VPC Flow Logs Report"
  documentation = file("./dashboards/vpc/docs/vpc_report_flow_logs.md")

  tags = merge(local.vpc_common_tags, {
    type     = "Report"
    category = "Logging"
  })

  container {

    card {
      query = query.vpc_count
      width = 3
    }

    card {
      query = query.vpc_no_flow_logs_count
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

    column "VPC ID" {
      href = "${dashboard.vpc_detail.url_path}?input.vpc_arn={{.ARN | @uri}}"
    }

    query = query.vpc_flow_logs_table
  }

}

query "vpc_flow_logs_table" {
  sql = <<-EOQ
    with flow_logs as (
      select
        resource_id,
        deliver_logs_status,
        traffic_type,
        log_destination,
        log_destination_type
      from
        aws_vpc_flow_log
    )
    select
      v.vpc_id as "VPC ID",
      v.tags ->> 'Name' as "Name",
      case
        when vpc_id in (select resource_id from aws_vpc_flow_log) then 'Enabled'
        else null
      end as "Flow Logs",
      f.deliver_logs_status as "Deliver Logs Status",
      f.traffic_type as "Traffic Type",
      f.log_destination as "Log Destination",
      f.log_destination_type as "Log Destination Type",
      a.title as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.arn as "ARN"
    from
      aws_vpc as v
      left join flow_logs as f on f.resource_id = v.vpc_id
      left join aws_account as a on v.account_id = a.account_id
    order by
      v.vpc_id;
  EOQ
}
