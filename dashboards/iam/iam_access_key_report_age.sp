variable "aws_iam_access_key_age_report_min_age" {
  default = 90
}

dashboard "aws_iam_access_key_age_report" {

  title = "AWS IAM Access Key Age Report"

  input "threshold_in_days" {
    title = "Threshold (days)"
    //type  = "text"
    width   = 2
    //default = "90"
  }

  container {

    # Analysis
    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          'Access Keys' as label
        from
          aws_iam_access_key
        where
          create_date < now() - '${var.aws_iam_access_key_age_report_min_age} days' :: interval  -- should use the threshold value...
      EOQ
      width = 2
    }

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          aws_iam_access_key
        where
          create_date > now() - '1 days' :: interval
          and create_date < now() - '${var.aws_iam_access_key_age_report_min_age} days' :: interval  -- should use the threshold value...
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '1-30 Days' as label
        from
          aws_iam_access_key
        where
          create_date between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
          and create_date < now() - '${var.aws_iam_access_key_age_report_min_age} days' :: interval  -- should use the threshold value...
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '30-90 Days' as label
        from
          aws_iam_access_key
        where
          create_date between symmetric now() - '30 days' :: interval and now() - '${var.aws_iam_access_key_age_report_min_age} days' :: interval
          and create_date < now() - '${var.aws_iam_access_key_age_report_min_age} days' :: interval  -- should use the threshold value...
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '90-365 Days' as label
        from
          aws_iam_access_key
        where
          create_date between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
          and create_date < now() - '${var.aws_iam_access_key_age_report_min_age} days' :: interval  -- should use the threshold value...
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '> 1 Year' as label
        from
          aws_iam_access_key
        where
          create_date <= now() - '1 year' :: interval
          and create_date < now() - '${var.aws_iam_access_key_age_report_min_age} days' :: interval  -- should use the threshold value...
      EOQ
      width = 2
      type  = "info"
    }
    
  }

  container {

    table {
      title = "Aged Access Keys"

      column "Account ID" {
        display = "none"
      }

      sql   = <<-EOQ
        select
          k.user_name as "User",
          k.access_key_id as "Access Key ID",
          k.status as "Status",
          -- date_trunc('day',age(now(),k.create_date))::text as "Age",
          now()::date - k.create_date::date as "Age in Days",
          k.create_date as "Create Date",
          a.title as "Account",
          k.account_id as "Account ID"
        from
          aws_iam_access_key as k,
          aws_account as a
        where
          a.account_id = k.account_id
          and k.create_date < now() - '${var.aws_iam_access_key_age_report_min_age} days' :: interval  -- should use the threshold value...
        order by
          create_date
      EOQ

    }

  }

}
