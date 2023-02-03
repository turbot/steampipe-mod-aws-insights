dashboard "api_gatewayv2_api_dashboard" {
  title         = "AWS API Gateway V2 API Dashboard"
  documentation = file("./dashboards/api_gatewayv2/docs/api_gatewayv2_api_dashboard.md")

  tags = merge(local.api_gatewayv2_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      width = 3
      query = query.api_gatewayv2_api_count
    }

    card {
      width = 3
      query = query.api_gatewayv2_api_default_endpoint_enabled
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Default Endpoint"
      query = query.api_gatewayv2_api_endpoint_status
      type  = "donut"
      width = 2

      series "count" {
        point "Disabled" {
          color = "ok"
        }
        point "Enabled" {
          color = "alert"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "APIs by Account"
      type  = "column"
      width = 3
      query = query.api_gatewayv2_api_by_account
    }

    chart {
      title = "APIs by Region"
      type  = "column"
      width = 3
      query = query.api_gatewayv2_api_by_region
    }

    chart {
      title = "APIs by Age"
      type  = "column"
      width = 3
      query = query.api_gatewayv2_api_by_age
    }

    chart {
      title = "APIs by Protocol"
      type  = "column"
      width = 3
      query = query.api_gatewayv2_api_by_protocol
    }

  }

}

# Cards

query "api_gatewayv2_api_count" {
  sql = <<-EOQ
    select
      count(*) as "APIs"
    from
      aws_api_gatewayv2_api
  EOQ
}

query "api_gatewayv2_api_default_endpoint_enabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Default Endpoint Enabled' as label,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      aws_api_gatewayv2_api
    where
      not disable_execute_api_endpoint;
  EOQ
}

# Assessments

query "api_gatewayv2_api_endpoint_status" {
  sql = <<-EOQ
    with apis_with_api_endpoint_status as (
      select
        name,
        case
          when disable_execute_api_endpoint then 'Disabled'
          else 'Enabled'
        end as api_endpoint
      from
        aws_api_gatewayv2_api
    )
    select
      api_endpoint,
      count(*)
    from
      apis_with_api_endpoint_status
    group by
      api_endpoint;
  EOQ
}

# Analysis

query "api_gatewayv2_api_by_account" {
  sql = <<-EOQ
    select
      acc.title as "Account",
      count(api.*)
    from
      aws_api_gatewayv2_api as api,
      aws_account as acc
    where
      api.account_id = acc.account_id
    group by
      acc.title
    order by
      acc.title;
  EOQ
}

query "api_gatewayv2_api_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*)
    from
      aws_api_gatewayv2_api
    group by
      region
    order by
      region;
  EOQ
}

query "api_gatewayv2_api_by_age" {
  sql = <<-EOQ
    with apis as (
      select
        title,
        created_date,
        to_char(created_date,
          'YYYY-MM') as creation_month
      from
        aws_api_gatewayv2_api
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_date)
              from
                apis
            )),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    tables_by_month as (
      select
        creation_month,
        count(*)
      from
        apis
      group by
        creation_month
    )
    select
      months.month,
      tables_by_month.count
    from
      months
      left join tables_by_month on months.month = tables_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "api_gatewayv2_api_by_protocol" {
  sql = <<-EOQ
    select
      protocol_type as "Protocol",
      count(*)
    from
      aws_api_gatewayv2_api
    group by
      protocol_type
    order by
      protocol_type;
  EOQ
}
