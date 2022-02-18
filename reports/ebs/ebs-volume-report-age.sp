

dashboard "aws_ebs_volume_age_report" {

  title = "AWS EBS Volume Age Report"


   container {

    # Analysis
    card {
      sql   = query.aws_ebs_volume_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from 
          aws_ebs_volume
        where 
          create_time > now() - '1 days' :: interval 
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
          aws_ebs_volume
        where 
          create_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval 
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
          aws_ebs_volume
        where 
          create_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval 
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
          aws_ebs_volume
        where 
          create_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
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
          aws_ebs_volume
        where 
          create_time <= now() - '1 year' :: interval 
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
          v.tags ->> 'Name' as "Name",
          v.volume_id as "Volume",
          date_trunc('day',age(now(),v.create_time))::text as "Age",
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
          v.create_time,
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