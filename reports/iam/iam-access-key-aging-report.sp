
dashboard "aws_iam_access_key_aging_report" {
  title = "AWS IAM Access Key Aging Report"

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
      EOQ
      width = 2
    }

    # #    # Assessments
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
      title = "Aged Access Keys"

      sql   = <<-EOQ
        select 
          k.user_name as "User",
          k.access_key_id as "Access Key ID",
          k.status as "Status",
          date_trunc('day',age(now(),k.create_date))::text as "Age",
          k.create_date as "Create Date",
          a.title as "Account",
          k.account_id as "Account ID"
        from 
          aws_iam_access_key as k,
          aws_account as a
        where
          a.account_id = k.account_id
          and k.create_date < now() - '90 days' :: interval  -- should use the threshold value...
        order by
          create_date
      
      EOQ
    }


  }
  

  
}