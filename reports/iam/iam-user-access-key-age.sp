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

dashboard "aws_iam_user_active_access_key_age_gt_90_days_report" {

  title = "AWS IAM User Active Access Age Greater Than 90 Days Report"

  container {

    card {
      sql   = query.aws_iam_user_active_access_key_age_gt_90_days_count.sql
      width = 4
    }
  }

  container {
    table {
      sql = <<-EOQ
        with access_keys as (
          select
            user_name,
            string_agg(access_key_id, ',') as access_key_ids,
            string_agg(status, ',') as status,
            string_agg(create_date :: text, ',') as create_date
          from
            aws.aws_iam_access_key
          group by
            user_name
        )
        select
          user_name,
          split_part(access_key_ids, ',', 1) as access_key_1,
          split_part(status, ',', 1) as access_key_1_status,
          split_part(create_date, ',', 1) as access_key_1_create_date,
          current_date - split_part(create_date, ',', 1)::date as access_key_1_age,
          case split_part(access_key_ids, ',', 2) when '' then 'NA' else split_part(access_key_ids, ',', 2) end as access_key_2,
          case split_part(status, ',', 2) when '' then 'NA' else split_part(status, ',', 2) end as access_key_2_status,
          case split_part(create_date, ',', 2) when '' then 'NA' else split_part(create_date, ',', 2) end as access_key_2_create_date,
          case split_part(create_date, ',', 2) when '' then 0 else current_date - split_part(create_date, ',', 2)::date end as access_key_2_age
        from
          access_keys
      EOQ
    }
  }
}
