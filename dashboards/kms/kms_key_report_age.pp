dashboard "kms_key_age_report" {

  title         = "AWS KMS Key Age Report"
  documentation = file("./dashboards/kms/docs/kms_key_report_age.md")

  tags = merge(local.kms_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      width = 2
      query = query.kms_key_count
    }

    card {
      type  = "info"
      width = 2
      query = query.kms_key_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.kms_key_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.kms_key_30_90_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.kms_key_90_365_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.kms_key_1_year_count
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Key ID" {
      href = "${dashboard.kms_key_detail.url_path}?input.key_arn={{.ARN | @uri}}"
    }

    query = query.kms_key_age_table
  }

}

query "kms_key_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_kms_key
    where
      creation_date > now() - '1 days' :: interval;
  EOQ
}

query "kms_key_30_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_kms_key
    where
      creation_date between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "kms_key_30_90_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_kms_key
    where
      creation_date between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "kms_key_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_kms_key
    where
      creation_date between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "kms_key_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_kms_key
    where
      creation_date <= now() - '1 year' :: interval;
  EOQ
}

query "kms_key_age_table" {
  sql = <<-EOQ
    select
      k.id as "Key ID",
      now()::date - k.creation_date::date as "Age in Days",
      k.creation_date as "Creation Date",
      k.key_state as "Key State",
      k.key_manager as "Key Manager",
      a.title as "Account",
      k.account_id as "Account ID",
      k.region as "Region",
      k.arn as "ARN"
    from
      aws_kms_key as k,
      aws_account as a
    where
      k.account_id = a.account_id
    order by
      k.creation_date,
      k.id;
  EOQ
}
