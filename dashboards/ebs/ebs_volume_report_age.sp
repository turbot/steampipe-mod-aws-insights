dashboard "aws_ebs_volume_age_report" {

  title = "AWS EBS Volume Age Report"

  tags = merge(local.ebs_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      width = 2
      sql   = query.aws_ebs_volume_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_ebs_volume_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_ebs_volume_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_ebs_volume_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_ebs_volume_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_ebs_volume_1_year_count.sql
    }

  }

  container {

    table {
      column "Account ID" {
        display = "none"
      }

      sql = query.aws_ebs_volume_age_table.sql
    }

  }

}

query "aws_ebs_volume_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_ebs_volume
    where
      create_time > now() - '1 days' :: interval;
  EOQ
}

query "aws_ebs_volume_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_ebs_volume
    where
      create_time between symmetric now() - '1 days' :: interval
      and now() - '30 days' :: interval;
  EOQ
}

query "aws_ebs_volume_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_ebs_volume
    where
      create_time between symmetric now() - '30 days' :: interval
      and now() - '90 days' :: interval;
  EOQ
}

query "aws_ebs_volume_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_ebs_volume
    where
      create_time between symmetric (now() - '90 days'::interval)
      and (now() - '365 days'::interval);
  EOQ
}

query "aws_ebs_volume_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_ebs_volume
    where
      create_time <= now() - '1 year' :: interval;
  EOQ
}

query "aws_ebs_volume_age_table" {
  sql = <<-EOQ
    select
      v.tags ->> 'Name' as "Name",
      v.volume_id as "Volume ID",
      now()::date - v.create_time::date as "Age in Days",
      v.create_time as "Create Time",
      v.state as "State",
      a.title as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.arn as "ARN"
    from
      aws_ebs_volume as v,
      aws_account as a
    where
      v.account_id = a.account_id
    order by
      v.tags ->> 'Name',
      v.volume_id;
  EOQ
}
