dashboard "aws_cloudtrail_trail_encryption_dashboard" {
  title = "AWS CloudTrail Trail Encryption Report"

  container {

    card {
      sql   = query.aws_cloudtrail_trail_count.sql
      width = 2
    }

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          'Unencrypted' as label,
          case count(*) when 0 then 'ok' else 'alert' end as type
        from
          aws_cloudtrail_trail
        where
          home_region = region
          and kms_key_id is null;
      EOQ
      width = 2
    }
  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      select
        t.title as "Trail",
        case when t.kms_key_id is not null then 'Enabled' else null end as "Encryption",
        a.title as "Account",
        t.account_id as "Account ID",
        t.region as "Region",
        t.arn as "ARN"
      from
        aws_cloudtrail_trail as t,
        aws_account as a
      where
        t.home_region = t.region
        and t.account_id = a.account_id;
    EOQ
    
  }

}