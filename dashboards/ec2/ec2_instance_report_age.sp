dashboard "aws_ec2_instance_age_report" {

  title = "AWS EC2 Instance Age Report"

  tags = merge(local.ec2_common_tags, {
    type     = "Report"
    category = "Age"
  })

   container {

    card {
      sql   = query.aws_ec2_instance_count.sql
      width = 2
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_ec2_instance_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_ec2_instance_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.aws_ec2_instance_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_ec2_instance_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.aws_ec2_instance_1_year_count.sql
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Instance ID" {
      href = "/aws_insights.dashboard.aws_ec2_instance_detail?input.instance_arn={{.ARN|@uri}}"
    }

    sql = query.aws_ec2_instance_age_table.sql
  }

}

query "aws_ec2_instance_24_hours_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_ec2_instance
    where
      launch_time > now() - '1 days' :: interval;
  EOQ
}

query "aws_ec2_instance_30_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_ec2_instance
    where
      launch_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "aws_ec2_instance_30_90_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_ec2_instance
    where
      launch_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "aws_ec2_instance_90_365_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_ec2_instance
    where
      launch_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "aws_ec2_instance_1_year_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_ec2_instance
    where
      launch_time <= now() - '1 year' :: interval;
  EOQ
}

query "aws_ec2_instance_age_table" {
  sql = <<-EOQ
    select
      i.instance_id as "Instance ID",
      i.tags ->> 'Name' as "Name",
      now()::date - i.launch_time::date as "Age in Days",
      i.launch_time as "Launch Time",
      i.instance_state as "State",
      a.title as "Account",
      i.account_id as "Account ID",
      i.region as "Region",
      i.arn as "ARN"
    from
      aws_ec2_instance as i,
      aws_account as a
    where
      i.account_id = a.account_id
    order by
      i.instance_id;
  EOQ
}
