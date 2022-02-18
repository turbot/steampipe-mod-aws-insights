

dashboard "aws_ec2_instance_age_report" {

  title = "AWS EC2 Instance Age Report"


   container {

    # Analysis
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
          launch_time > now() - '1 days' :: interval
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
          launch_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
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
          launch_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
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
          launch_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
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
          launch_time <= now() - '1 year' :: interval
      EOQ
      width = 2
      type = "info"
    }

  }

  container {


    table {

      sql = <<-EOQ
        select
          v.title as "Instance",
          'instance_id' as "Id",
          date_trunc('day',age(now(),v.launch_time))::text as "Age",
          v.launch_time as "Create Time",
          a.title as "Account",
          v.account_id as "Account ID",
          v.instance_state as "State",
          v.arn as "ARN"
        from
          aws_ec2_instance as v,
          aws_account as a
        where
          v.account_id = a.account_id
        order by
          v.launch_time,
          v.title

      EOQ
    }


  }

}


/*

select
  'value 1' as value,
  'value 2' as value

*/