
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
          'Users with excessive permissions' as label,
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
          'Excessive user service permissiions' as label,
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


    # card {
    #   sql   = <<-EOQ
    #     select
    #       count(*) as value,
    #       'Last 30 Days' as label
    #     from 
    #       aws_iam_access_advisor,
    #       aws_iam_user
    #     where 
    #       principal_arn = arn 
    #       and last_authenticated  > now() - '30 days' :: interval 

    #   EOQ
    #   width = 2
    #   type = "info"
    # }

    # card {
    #   sql   = <<-EOQ
    #     select
    #       count(*) as value,
    #       '30-90 Days' as label
    #     from 
    #       aws_iam_access_advisor,
    #       aws_iam_user
    #     where 
    #       principal_arn = arn
    #       and last_authenticated between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval 
    #   EOQ
    #   width = 2
    #   type = "info"
    # }

    # card {
    #   sql   = <<-EOQ
    #     select
    #       count(*) as value,
    #       '90-365 Days' as label
    #     from 
    #       aws_iam_access_advisor,
    #       aws_iam_user
    #     where 
    #       principal_arn = arn
    #       and last_authenticated between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
    #   EOQ
    #   width = 2
    #   type = "info"
    # }

    # card {
    #   sql   = <<-EOQ
    #     select
    #       count(*) as value,
    #       '> 1 Year' as label
    #     from 
    #       aws_iam_access_advisor,
    #       aws_iam_user
    #     where 
    #       principal_arn = arn
    #       and last_authenticated  <= now() - '1 year' :: interval 
    #   EOQ
    #   width = 2
    #   type = "info"
    # }


    # card {
    #   sql   = <<-EOQ
    #     select
    #       count(*) as value,
    #       'Never in Tracking Period' as label,
    #       case 
    #         when count(*) = 0 then 'ok'
    #         else 'alert'
    #       end as type
    #     from
    #       aws_iam_access_advisor,
    #       aws_iam_user
    #     where 
    #       principal_arn = arn
    #       and last_authenticated is null
    #   EOQ
    #   width = 2
    # }

  }


  container { 
    title = "Access Advisor"


    # per, https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_access-advisor-view-data.html ,
    #  The tracking period for services is for the last 400 days.
    table {
      //width = 8
      title = "Services granted access"
      sql   = <<-EOQ
        select
          principal_arn as "Principal",
          service_name as "Service",
          service_namespace as "Service Namespace",
          case
            when last_authenticated is null then 'Never in Tracking Period'
            else date_trunc('day',age(now(),last_authenticated))::text
          end as "Last Authenticted",
          last_authenticated as "Last Authenticted Timestamp",
          last_authenticated_entity as "Last Authenticted Entity",
          last_authenticated_region as "Last Authenticted Region"
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
