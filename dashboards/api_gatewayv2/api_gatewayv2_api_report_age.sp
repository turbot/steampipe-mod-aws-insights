dashboard "api_gatewayv2_api_report_age" {
  title         = "AWS API Gateway V2 API Age Report"
  documentation = file("./dashboards/api_gatewayv2/docs/api_gatewayv2_api_report_age.md")

  tags = merge(local.api_gatewayv2_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.aws_api_gatewayv2_api_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_api_gatewayv2_api_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_api_gatewayv2_api_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_api_gatewayv2_api_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.aws_api_gatewayv2_api_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.aws_api_gatewayv2_api_1_year_count
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.api_gatewayv2_api_detail.url_path}?input.api_id={{.ID | @uri}}"
    }

    query = query.aws_api_gatewayv2_api_table
  }
}

query "aws_api_gatewayv2_api_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_api_gatewayv2_api
    where
      created_date > now() - '1 days' :: interval;
  EOQ
}

query "aws_api_gatewayv2_api_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_api_gatewayv2_api
    where
      created_date between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "aws_api_gatewayv2_api_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_api_gatewayv2_api
    where
      created_date between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "aws_api_gatewayv2_api_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_api_gatewayv2_api
    where
      created_date between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "aws_api_gatewayv2_api_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_api_gatewayv2_api
    where
      created_date <= now() - '1 year' :: interval;
  EOQ
}

query "aws_api_gatewayv2_api_table" {
  sql = <<-EOQ
    select
      api.name as "Name",
      api.api_id as "ID",
      now()::date - api.created_date::date as "Age in Days",
      api.created_date as "Create Time",
      acc.title as "Account",
      api.protocol_type as "Protocol",
      api.account_id as "Account ID",
      api.region as "Region"
    from
      aws_api_gatewayv2_api as api,
      aws_account as acc
    where
      api.account_id = acc.account_id
    order by
      api.name;
  EOQ
}
