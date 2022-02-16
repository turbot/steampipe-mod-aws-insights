query "aws_iam_user_mfa_not_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'MFA Enabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_iam_user
    where
      not mfa_enabled
  EOQ
}

dashboard "aws_iam_user_mfa_report" {

  title = "AWS IAM User MFA Report"

  container {

    card {
      sql   = query.aws_iam_user_mfa_not_enabled_count.sql
      width = 2
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
          split_part(access_key_ids, ',', 1) as key1,
          split_part(status, ',', 1) as key1_status,
          split_part(create_date, ',', 1) as key1_create_date,
          current_date - split_part(create_date, ',', 1)::date as key1_age,
          case split_part(access_key_ids, ',', 2) when '' then 'NA' else split_part(access_key_ids, ',', 2) end as key2,
          case split_part(status, ',', 2) when '' then 'NA' else split_part(status, ',', 2) end as key2_status,
          case split_part(create_date, ',', 2) when '' then 'NA' else split_part(create_date, ',', 2) end as key2_create_date,
          case split_part(create_date, ',', 2) when '' then 0 else current_date - split_part(create_date, ',', 2)::date end as key2_age
        from
          access_keys;
      EOQ
    }
  }
}
