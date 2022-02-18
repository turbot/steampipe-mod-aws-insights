
variable "iam_user_excessive_privilege_report_threshold_in_days" {
  default = 90
}
dashboard "iam_user_excessive_privilege_report" {

  title = "AWS IAM User Excessive Privilege Report"

  container {

    input "threshold_in_days" {
      title = "Threshold (days)"
      //type  = "text"
      width   = 2
      //default = "90"
    }

  }


  container { 
    card {
       sql   = <<-EOQ
        select
          count(*) as value,
          'Users' as label
        from
          aws_iam_user
      EOQ
      width = 2
    }



card {
      sql   = <<-EOQ
        select
          count(distinct principal_arn) as value,
          'Users with Excessive Permissions' as label,
          case 
            when count(*) = 0 then 'ok'
            else 'alert'
          end as type
        from
          aws_iam_access_advisor,
          aws_iam_user
        where 
          principal_arn = arn
          and coalesce(last_authenticated, now() - '400 days' :: interval ) < now() - '${var.iam_user_excessive_privilege_report_threshold_in_days} days' :: interval  -- should use the thrreshold value...

      EOQ
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          'Excessive Permissiions' as label,
          case 
            when count(*) = 0 then 'ok'
            else 'alert'
          end as type
        from
          aws_iam_access_advisor,
          aws_iam_user
        where 
          principal_arn = arn
          and coalesce(last_authenticated, now() - '400 days' :: interval ) < now() - '${var.iam_user_excessive_privilege_report_threshold_in_days} days' :: interval  -- should use the thrreshold value...

      EOQ
      width = 2
    }

  }


  container { 


    # per, https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_access-advisor-view-data.html ,
    #  The tracking period for services is for the last 400 days.
    table {
      sql   = <<-EOQ
        select
          principal_arn as "Principal",
          service_name as "Service",
          service_namespace as "Service Namespace",
          -- case
          --  when last_authenticated is null then 'Never in Tracking Period'
          --  else date_trunc('day',age(now(),last_authenticated))::text
          -- end as "Last Authenticated",
          -- cant do: invalid input syntax for type integer: "Never in Tracking Period"
          case
            when last_authenticated is null then 'Never in Tracking Period'
            else (now()::date  - last_authenticated::date)::text
          end as "Last Authenticted (Days)",
          last_authenticated as "Last Authenticated Timestamp",
          last_authenticated_entity as "Last Authenticated Entity",
          last_authenticated_region as "Last Authenticated Region"
        from
          aws_iam_access_advisor,
          aws_iam_user
        where 
          principal_arn = arn
          and coalesce(last_authenticated, now() - '400 days' :: interval ) < now() - '${var.iam_user_excessive_privilege_report_threshold_in_days} days' :: interval  -- should use the thrreshold value...
      EOQ
    }
  }

}
