

dashboard "aws_ec2_instance_age_report" {

  title = "AWS EC2 Instance Age Report"

   container {

    card {
      sql   = query.aws_ec2_instance_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          aws_ec2_instance
        where
          launch_time > now() - '1 days' :: interval;
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '1-30 Days' as label
        from
          aws_ec2_instance
        where
          launch_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '30-90 Days' as label
        from
          aws_ec2_instance
        where
          launch_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '90-365 Days' as label
        from
          aws_ec2_instance
        where
          launch_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
      EOQ
      width = 2
      type = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '> 1 Year' as label
        from
          aws_ec2_instance
        where
          launch_time <= now() - '1 year' :: interval;
      EOQ
      width = 2
      type = "info"
    }

  }

  container {

    table {

      column "Account ID" {
        display = "none"
      }

      sql = <<-EOQ
        select
          i.tags ->> 'Name' as "Name",
          i.instance_id as "Instance ID",
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
          i.launch_time,
          i.title;
      EOQ

    }

  }

}


/*

select
  'value 1' as value,
  'value 2' as value

*/