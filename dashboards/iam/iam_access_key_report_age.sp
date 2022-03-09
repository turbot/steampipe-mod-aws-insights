dashboard "aws_iam_access_key_age_report" {

  title = "AWS IAM Access Key Age Report"
  documentation = file("./dashboards/iam/docs/iam_access_key_report_age.md")

  tags = merge(local.iam_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      width = 2
      sql   = query.aws_iam_access_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_iam_access_key_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_iam_access_key_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_iam_access_key_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_iam_access_key_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_iam_access_key_1_year_count.sql
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    sql = query.aws_iam_access_key_age_table.sql
  }

}

query "aws_iam_access_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Access Keys' as label
    from
      aws_iam_access_key;
  EOQ
}

query "aws_iam_access_key_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_iam_access_key
    where
      create_date > now() - '1 days' :: interval;
  EOQ
}

query "aws_iam_access_key_30_days_count" {
  sql = <<-EOQ
     select
        count(*) as value,
        '1-30 Days' as label
      from
        aws_iam_access_key
      where
        create_date between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "aws_iam_access_key_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_iam_access_key
    where
      create_date between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "aws_iam_access_key_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_iam_access_key
    where
      create_date between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "aws_iam_access_key_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_iam_access_key
    where
      create_date <= now() - '1 year' :: interval;
  EOQ
}

query "aws_iam_access_key_age_table" {
  sql = <<-EOQ
    select
      k.user_name as "User",
      k.access_key_id as "Access Key ID",
      k.status as "Status",
      now()::date - k.create_date::date as "Age in Days",
      k.create_date as "Create Date",
      a.title as "Account",
      k.account_id as "Account ID"
    from
      aws_iam_access_key as k,
      aws_account as a
    where
      a.account_id = k.account_id
    order by
      k.user_name;
  EOQ
}
