
query "aws_iam_principal_input" {
  sql = <<EOQ
    select
      arn as label,  --title as label
      arn as value
    from
      aws_iam_user

    union all select
      arn as label,
      arn as value
    from
      aws_iam_role

    union all select
      arn as label,
      arn as value
    from
      aws_iam_group
    order by
      value;

    union all select
      arn as label,
      arn as value
    from
      aws_iam_policy
    order by
      value;
EOQ
}

dashboard "iam_excessive_privilege_report" {

  title = "AWS IAM Excessive Privilege Report"

  container {
    input "principal_arn" {
      title = "Principal"
      sql   = query.aws_iam_principal_input.sql
      width = 4
    }

    input "threshold_in_days" {
      title = "Threshold (days)"
      //type  = "text"
      width   = 2
      //default = "90"
    }

  }


  # bug - https://github.com/turbot/steampipe-plugin-aws/issues/900
  # container { 
  #   card {
  #      sql   = <<-EOQ
  #       select
  #         count(*) as value,
  #         'Accessible Services'
  #       from
  #         aws_iam_access_advisor 
  #       where 
  #         principal_arn = 'arn:aws:iam::876515858155:user/jsmyth'
  #     EOQ
  #     width = 2
  #   }
  # }


  container { 
    title = "Access Advisor"

    # bug - https://github.com/turbot/steampipe-plugin-aws/issues/900
    # chart {
    #   type = "table"
    #   width = 4
    #   title = "Services granted access"
    #   sql   = <<-EOQ
    #     with last_access_times as (
    #       select
    #         service_name,
    #         case
    #           when last_authenticated is null 
    #             then '> 400 days'
    #           when last_authenticated > current_date - interval '24 hours'
    #             then 'Today'
    #           when last_authenticated > current_date - interval '7 days'
    #             then 'This Week'
    #           when last_authenticated > current_date - interval '1 month'
    #             then 'This Month'
    #           when last_authenticated > current_date - interval '3 months'
    #             then 'This Quarter'
    #           when last_authenticated > current_date - interval '1 year'
    #             then 'This Year'
    #           else 'Last Year'
    #         end as last_access_bucket
    #       from
    #         aws_iam_access_advisor 
    #       where 
    #         principal_arn = 'arn:aws:iam::876515858155:user/jsmyth'
    #     )
    #     select 
    #       last_access_bucket,
    #       count(*)
    #     from
    #       last_access_times
    #     group by 
    #       last_access_bucket

    #   EOQ
    # }



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
          aws_iam_access_advisor 
        where 
          principal_arn = 'arn:aws:iam::876515858155:user/jsmyth'
          and coalesce(last_authenticated, now() - '400 days' :: interval ) < now() - '90 days' :: interval  -- should use the thrreshold value...

      EOQ
    }
  }

}
