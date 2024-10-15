dashboard "dynamodb_table_age_report" {

  title         = "AWS DynamoDB Table Age Report"
  documentation = file("./dashboards/dynamodb/docs/dynamodb_table_report_age.md")

  tags = merge(local.dynamodb_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.dynamodb_table_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.dynamodb_table_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.dynamodb_table_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.dynamodb_table_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.dynamodb_table_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.dynamodb_table_1_year_count
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.dynamodb_table_detail.url_path}?input.table_arn={{.ARN | @uri}}"
    }

    query = query.dynamodb_table_age_table
  }

}

query "dynamodb_table_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_dynamodb_table
    where
      creation_date_time > now() - '1 days' :: interval;
  EOQ
}

query "dynamodb_table_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_dynamodb_table
    where
      creation_date_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "dynamodb_table_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_dynamodb_table
    where
      creation_date_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "dynamodb_table_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_dynamodb_table
    where
      creation_date_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "dynamodb_table_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_dynamodb_table
    where
      creation_date_time <= now() - '1 year' :: interval;
  EOQ
}

query "dynamodb_table_age_table" {
  sql = <<-EOQ
    select
      d.name as "Name",
      now()::date - d.creation_date_time::date as "Age in Days",
      d.creation_date_time as "Create Time",
      d.table_status as "State",
      a.title as "Account",
      d.account_id as "Account ID",
      d.region as "Region",
      d.arn as "ARN"
    from
      aws_dynamodb_table as d,
      aws_account as a
    where
      d.account_id = a.account_id
    order by
      d.creation_date_time,
      d.name;
  EOQ
}
