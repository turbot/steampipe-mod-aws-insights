dashboard "aws_iam_user_excessive_privilege_report" {

  title = "AWS IAM User Excessive Privilege Report"

  tags = merge(local.iam_common_tags, {
    type     = "Report"
    category = "Permissions"
  })

   input "threshold_in_days" {
     title = "Threshold"
     width = 2
     option "30" {
       label = "30 days"
     }
     option "60" {
       label = "60 days"
     }
     option "90" {
       label = "90 days"
     }
   }

  container {

    card {
      sql   = query.aws_iam_user_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_user_with_excessive_permissions_count.sql
      width = 2

      args  = {
        threshold_in_days = self.input.threshold_in_days.value
      }
    }

    card {
      sql   = query.aws_iam_excessive_permissions_count.sql
      width = 2

      args  = {
        threshold_in_days = self.input.threshold_in_days.value
      }
    }
  }

  # Per, https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_access-advisor-view-data.html,
  # The tracking period for services is for the last 400 days.
  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "User Name" {
      href = "/aws_insights.dashboard.aws_iam_user_detail?input.user_arn={{.row.ARN | @uri}}"
    }

    sql = query.aws_iam_user_excessive_permissions_report.sql

    args  = {
      threshold_in_days = self.input.threshold_in_days.value
    }
  }

}

query "aws_iam_user_with_excessive_permissions_count" {
  sql = <<-EOQ
    select
      count(distinct principal_arn) as value,
      'Users With Excessive Permissions' as label,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      aws_iam_access_advisor,
      aws_iam_user
    where
      principal_arn = arn
      and coalesce(last_authenticated, now() - '400 days' :: interval ) < now() - '$1 days' :: interval;
  EOQ

  param "threshold_in_days" {}
}

query "aws_iam_excessive_permissions_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Excessive Permissions' as label,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      aws_iam_access_advisor,
      aws_iam_user
    where
      principal_arn = arn
      and coalesce(last_authenticated, now() - '400 days' :: interval ) < now() - '$1 days' :: interval;
  EOQ

  param "threshold_in_days" {}
}

query "aws_iam_user_excessive_permissions_report" {
  sql = <<-EOQ
    select
      u.name as "User Name",
      aa.principal_arn as "Principal",
      aa.service_name as "Service",
      aa.service_namespace as "Service Namespace",
      case
        when aa.last_authenticated is null then 'Never in tracking period'
        else (now()::date  - aa.last_authenticated::date)::text
      end as "Last Authenticated (Days)",
      aa.last_authenticated as "Last Authenticated Timestamp",
      aa.last_authenticated_entity as "Last Authenticated Entity",
      aa.last_authenticated_region as "Last Authenticated Region",
      a.title as "Account",
      a.account_id as "Account ID",
      u.arn as "ARN"
    from
      aws_iam_access_advisor as aa,
      aws_iam_user as u,
      aws_account as a
    where
      u.account_id = a.account_id
      and aa.principal_arn = u.arn
      and coalesce(aa.last_authenticated, now() - '400 days' :: interval ) < now() - '$1 days' :: interval
    order by
      u.name;
  EOQ

  param "threshold_in_days" {}
}
