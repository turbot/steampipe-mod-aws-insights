query "aws_vpc_count" {
  sql = <<-EOQ
    select count(*) as "VPCs" from aws_vpc
  EOQ
}

query "aws_vpc_no_subnet_count" {
 sql = <<-EOQ
    select 
       count(*) as value,
       'VPCs With No Subnets' as label,
       case when count(*) = 0 then 'ok' else 'alert' end as type
      from 
        aws_vpc as vpc
        left join aws_vpc_subnet as s on vpc.vpc_id = s.vpc_id
      where
        s.subnet_id is null
  EOQ
}

query "aws_vpc_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(v.*) as "volumes"
    from
      aws_vpc as v,
      aws_account as a
    where
      a.account_id = v.account_id
    group by
      account
    order by
      account
  EOQ
}

query "aws_vpc_by_region" {
  sql = <<-EOQ
    select 
      region as "Region",
      count(*) as "VPCs"
    from 
      aws_vpc
    group by
      region
    order by
      region
  EOQ
}

query "aws_vpc_by_rfc1918_range" {
  sql = <<-EOQ
    with cidr_buckets as (
      select 
        vpc_id,
        title,
        b ->> 'CidrBlock' as cidr,
        case
          when (b ->> 'CidrBlock')::cidr <<= '10.0.0.0/8'::cidr then '10.0.0.0/8'
          when (b ->> 'CidrBlock')::cidr <<= '172.16.0.0/12'::cidr then '172.16.0.0/12'
          when (b ->> 'CidrBlock')::cidr <<= '192.168.0.0/16'::cidr then '192.168.0.0/16'
          else 'Public Range'
        end as rfc1918_bucket
      from
        aws_vpc,
        jsonb_array_elements(cidr_block_association_set) as b
    )
    select 
      rfc1918_bucket,
      count(*)
    from 
      cidr_buckets
    group by 
      rfc1918_bucket
    order by
      rfc1918_bucket
  EOQ
}

query "aws_vpc_by_size" {
  sql = <<-EOQ
    with vpc_size as (
      select
        vpc_id,
        cidr_block,
        concat( 
          '/', masklen(cidr_block), 
          ' (', power(2, 32 - masklen(cidr_block :: cidr)), ')'
        ) as size
      from
        aws_vpc
    )
    select
      size,
      count(*)
    from
      vpc_size
    group by
      size
  EOQ
}

query "aws_vpc_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount)::numeric as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Virtual Private Cloud'
    group by
      period_start
    order by
      period_start
  EOQ
}

query "aws_vpc_cost_by_usage_types_12mo" {
  sql = <<-EOQ
    select
       usage_type,
       sum(unblended_cost_amount)::numeric as "Unblended Cost"
       -- sum(unblended_cost_amount)::numeric::money as "Unblended Cost"

    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Virtual Private Cloud'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      usage_type
    having
      round(sum(unblended_cost_amount)::numeric,2) > 0
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_vpc_cost_top_usage_types_mtd" {
  sql = <<-EOQ
    select
       usage_type,
       sum(unblended_cost_amount)::numeric as "Unblended Cost"
       --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"

    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Virtual Private Cloud'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
    group by
      period_start,
      usage_type
    having
      round(sum(unblended_cost_amount)::numeric,2) > 0
    order by
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_vpc_cost_by_account_mtd" {
  sql = <<-EOQ
    select
       a.title as "account",
       sum(unblended_cost_amount)::numeric as "Unblended Cost"
       --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'Amazon Virtual Private Cloud'
      and period_end > date_trunc('month', CURRENT_DATE::timestamp)
    group by
      account
    order by
      account
  EOQ
}

query "aws_vpc_cost_by_account_12mo" {
  sql = <<-EOQ
    select
       a.title as "account",
       sum(unblended_cost_amount)::numeric as "Unblended Cost"
       --        sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from
      aws_cost_by_service_monthly as c,
      aws_account as a
    where
      a.account_id = c.account_id
      and service = 'Amazon Virtual Private Cloud'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by
      account
    order by
      account
  EOQ
}

query "aws_vpc_monthly_forecast_table" {
  sql = <<-EOQ
    with monthly_costs as (
      select
        period_start,
        period_end,
        case
          when date_trunc('month', period_start) = date_trunc('month', CURRENT_DATE::timestamp) then 'Month to Date'
          when date_trunc('month', period_start) = date_trunc('month', CURRENT_DATE::timestamp - interval '1 month') then 'Previous Month'
          else to_char (period_start, 'Month')
        end as period_label,
        period_end::date - period_start::date as days,
        sum(unblended_cost_amount)::numeric::money as unblended_cost_amount,
        (sum(unblended_cost_amount) / (period_end::date - period_start::date))::numeric::money as average_daily_cost,
        date_part('days', date_trunc ('month', period_start) + '1 MONTH'::interval - '1 DAY'::interval) as days_in_month,
        sum(unblended_cost_amount) / (period_end::date - period_start::date ) * date_part('days', date_trunc ('month', period_start) + '1 MONTH'::interval - '1 DAY'::interval)::numeric::money as forecast_amount
      from
        aws_cost_by_service_usage_type_monthly as c
      where
        service = 'Amazon Virtual Private Cloud'
        and date_trunc('month', period_start) >= date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
      group by
        period_start,
        period_end
    )
    select
      period_label as "Period",
      unblended_cost_amount as "Cost",
      average_daily_cost as "Daily Avg Cost"
    from
      monthly_costs
    union all
    select
      'This Month (Forecast)' as "Period",
      (select forecast_amount from monthly_costs where period_label = 'Month to Date') as "Cost",
      (select average_daily_cost from monthly_costs where period_label = 'Month to Date') as "Daily Avg Cost"
  EOQ
}

dashboard "aws_vpc_dashboard" {
  title = "AWS VPC Dashboard"

  container {

    # Analysis
    card {
      sql   = query.aws_vpc_count.sql
      width = 2
    }

    # Costs
    card {
      sql = <<-EOQ
        select
          'Cost - MTD' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_monthly
        where
          service = 'Amazon Virtual Private Cloud'
          and period_end > date_trunc('month', CURRENT_DATE::timestamp)
      EOQ
      width = 2
      type  = "info"
      icon  = "currency-dollar"
    }

    card {
      sql = <<-EOQ
        select
          'Cost - Previous Month' as label,
          sum(unblended_cost_amount)::numeric::money as value
        from
          aws_cost_by_service_monthly
        where
          service = 'Amazon Virtual Private Cloud'
          and date_trunc('month', period_start) = date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
      EOQ
      width = 2
      type  = "info"
      icon  = "currency-dollar"
    }

   # Assessments
    card {
      sql = <<-EOQ
        select
          count(*) as value,
          'Default VPCs' as label,
          case count(*) when 0 then 'ok' else 'alert' end as type
        from
          aws_vpc
        where
          is_default
      EOQ
      width = 2
    }

    card {
      sql = <<-EOQ
        select
          count(*) filter(where vpc_id not in (select resource_id from aws_vpc_flow_log)) as value,
          'Flow Logs Not Configured' as label,
          case count(*) filter(where vpc_id not in (select resource_id from aws_vpc_flow_log))
            when 0 then 'ok'
            else 'alert'
          end as type
        from
          aws_vpc
      EOQ
      width = 2
    }

    card {
      sql = query.aws_vpc_no_subnet_count.sql
      width = 2
    }
  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Default VPC"
      type  = "donut"
      width = 4
      sql   = <<-EOQ
        select
          case
            when is_default then 'Default'
            else 'Non-Default'
          end as default_status,
          count(*)
        from
          aws_vpc
        group by
          is_default
      EOQ
    }

    chart {
      title = "VPC Flow Logs"
      type  = "donut"
      width = 4
      sql   = <<-EOQ
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
          flow_logs_configured,
          count(*)
        from
          vpc_logs
        group by
          flow_logs_configured
      EOQ
    }

    chart {
      title = "Empty VPC (No subnets)"
      type  = "donut"
      width = 4
      sql   = <<-EOQ
        with by_empty as (
          select 
            vpc.vpc_id,
            case when s.subnet_id is null then 'empty' else 'non-empty' end as status
          from 
            aws_vpc as vpc
            left join aws_vpc_subnet as s on vpc.vpc_id = s.vpc_id
        )
        select
          status,
          count(*)
        from
          by_empty
        group by
          status
      EOQ
    }
  }

  container {
    title = "Cost"
    width = 6

    # Costs
    table {
      width = 6
      title = "Forecast"
      sql   = query.aws_vpc_monthly_forecast_table.sql
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      sql   = query.aws_vpc_cost_per_month.sql
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "VPCs by Account"
      sql   = query.aws_vpc_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "VPCs by Region"
      sql   = query.aws_vpc_by_region.sql
      type  = "column"
      legend {
        position = "bottom"
      }
      width = 3
    }

    chart {
      title = "VPCs by Size"
      sql   = query.aws_vpc_by_size.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "VPCs by RFC1918 Range"
      sql   = query.aws_vpc_by_rfc1918_range.sql
      type  = "column"
      width = 3
    }
  }

  #container {
  #  title = "Costs"
  #  width = 4
  #
  #  chart {
  #    title = "VPC Monthly Unblended Cost"
  #    type  = "line"
  #    sql   = query.aws_vpc_cost_per_month.sql
  #  }
  #
  #  chart {
  #    title = "VPC Cost by Usage Type - MTD"
  #    type  = "donut"
  #    sql   = query.aws_vpc_cost_top_usage_types_mtd.sql
  #    width = 2
  #  
  #    legend {
  #      position = "bottom"
  #    }
  #  }
  #
  #  chart {
  #    title = "VPC Cost by Usage Type - 12 months"
  #    type  = "donut"
  #    sql   = query.aws_vpc_cost_by_usage_types_12mo.sql
  #    width = 2
  #  
  #    legend {
  #      position = "right"
  #    }
  #  }
  #
  #chart {
  #  title = "VPC Cost by Account - MTD"
  #  type  = "donut"
  #  sql   = query.aws_vpc_cost_by_account_mtd.sql
  #  width = 2
  #}

  #  chart {
  #    title = "VPC Cost by Account - 12 months"
  #    type  = "donut"
  #    sql   = query.aws_vpc_cost_by_account_12mo.sql
  #    width = 2
  #  }
  #}
}
 
# container {
#   title  = "Performance & Utilization"
# 
#   No performance metrics for VPC?
#   
# }

# container {
#   title   = "Resources by Age"
#
#   No create time data for VPC?
#
# }
