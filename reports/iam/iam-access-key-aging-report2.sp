query "aws_iam_user_active_access_key_age_gt_90_days_count" {
  sql = <<-EOQ
    select
      count(distinct user_name) as value,
      'Users With Access Key Age Greater Than 90 Days' as label,
      case count(distinct user_name) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_iam_access_key
    where
      create_date > now() - interval '90 days' and
      status = 'Active'
  EOQ
}

dashboard "aws_iam_user_access_key_age_report_2" {

  title = "AWS IAM Access Key Aging Report 2"

  container {

    # Analysis
    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          'Access Keys' as label
        from
          aws_iam_access_key
      EOQ
      width = 2
    }

    # Assessments
    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          'Aged Keys' as label,
          case when count(*) = 0 then 'ok' else 'alert' end as type
        from
          aws_iam_access_key
        where
          create_date < now() - '90 days' :: interval;  -- should use the threshold value...
      EOQ
      width = 2
    }
  }

  container {
    table {
      sql = <<-EOQ
        with access_keys as (
          select
            k.user_name,
            string_agg(k.access_key_id, ',') as access_key_ids,
            string_agg(k.status, ',') as status,
            string_agg(k.create_date::text, ',') as create_date,
            a.account_id,
            a.title
          from
            aws.aws_iam_access_key as k,
            aws_account as a
          where
            a.account_id = k.account_id
          group by
            user_name,
            a.account_id,
            a.title
        )
        select
          user_name as "User",
          split_part(access_key_ids, ',', 1) as "Access Key 1",
          split_part(status, ',', 1) as "Key 1 Status",
          date_trunc('day', age(now(), split_part(create_date, ',', 1)::date))::text as "Key 1 Age",
          split_part(create_date, ',', 1)::date as "Key 1 Create Date",
          case split_part(access_key_ids, ',', 2) when '' then 'NA' else split_part(access_key_ids, ',', 2) end as "Access Key 2",
          case split_part(status, ',', 2) when '' then 'NA' else split_part(status, ',', 2) end as "Key 2 Status",
          case split_part(create_date, ',', 2) when '' then 'NA' else date_trunc('day', age(now(), split_part(create_date, ',', 2)::date))::text end as "Key 2 Age",
          case split_part(create_date, ',', 2) when '' then 'NA' else split_part(create_date, ',', 2) end as "Key 2 Create Date",
          title as "Account",
          account_id as "Account ID"
        from
          access_keys
      EOQ
    }
  }
}
