report "aws_vpc_dashboard" {
  title = "AWS VPC Dashboard"

  container {
    # Analysis
    card {
      sql = <<-EOQ
        select count(*) as "VPCs" from aws_vpc;
      EOQ

      width = 2
    }

    card {
      sql = <<-EOQ
        with vpc_with_active_flow_logs as (
          select
            count(f.resource_id),
            v.vpc_id
          from
            aws_vpc as v
            left join aws_vpc_flow_log as f on v.vpc_id = f.resource_id
          group by
            v.vpc_id
        )
        select
          count(vpc_id) as value,
          'VPC with FlowLog Disabled' as label,
          case count(*) when 0 then 'ok' else 'alert' end as style
        from
          vpc_with_active_flow_logs
        where
          count = 0;
      EOQ
      width = 2
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "VPCs by Account"
      sql   = <<-EOQ
        select
          a.title as "account",
          count(v.*) as "vpcs"
        from
          aws_vpc as v,
          aws_account as a
        where
          a.account_id = v.account_id
        group by
          account
        order by
          account;
      EOQ
      type  = "column"
      width = 3
    }

    chart {
      title = "VPCs by Region"
      sql   = <<-EOQ
        select
          region as "Region",
          count(*) as "vpcs"
        from
          aws_vpc
        group by region
        order by region;
      EOQ
      type  = "column"
      width = 3
    }
  }

  # donut charts in a 2 x 2 layout
  container {
    title = "Assessments"

    chart {
      title = "VPC State"
      sql   = <<-EOQ
        select
          state,
          count(state)
        from
          aws_vpc
        group by state;
      EOQ
      type  = "donut"
      width = 3
    }

    chart {
      title = "Instance Tenancy"
      sql   = <<-EOQ
        select
          instance_tenancy,
          count(instance_tenancy)
        from
          aws_vpc
        group by instance_tenancy;
      EOQ
      type  = "donut"
      width = 3
    }
  }
}