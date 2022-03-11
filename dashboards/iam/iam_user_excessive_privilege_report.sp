variable "aws_iam_user_excessive_privilege_report_threshold_in_days" {
  default = 90
}

dashboard "aws_iam_user_excessive_privilege_report" {

  title = "AWS IAM User Excessive Privilege Report"

  tags = merge(local.iam_common_tags, {
    type     = "Report"
    category = "Permissions"
  })

  # input "threshold_in_days" {
  #   title = "Threshold (days)"
  #   width = 2
  # }

  container {

    card {
      sql   = query.aws_iam_user_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_users_with_excessive_permissions.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_excessive_permissions_count.sql
      width = 2
    }
  }

    # per, https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_access-advisor-view-data.html ,
    #  The tracking period for services is for the last 400 days.
  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }
    sql = query.aws_iam_user_excessive_permissions_table.sql
  }

}

query "aws_iam_users_with_excessive_permissions" {
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
      and coalesce(last_authenticated, now() - '400 days' :: interval ) < now() - '${var.aws_iam_user_excessive_privilege_report_threshold_in_days} days' :: interval;
      -- should use the threshold value...
  EOQ
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
      and coalesce(last_authenticated, now() - '400 days' :: interval ) < now() - '${var.aws_iam_user_excessive_privilege_report_threshold_in_days} days' :: interval;  -- should use the threshold value...
  EOQ
}

query "aws_iam_user_excessive_permissions_table" {
  sql = <<-EOQ
    select
      name as "User Name",
      principal_arn as "Principal",
      service_name as "Service",
      service_namespace as "Service Namespace",
      case
        when last_authenticated is null then 'Never in Tracking Period'
        else (now()::date  - last_authenticated::date)::text
      end as "Last Authenticated (Days)",
      last_authenticated as "Last Authenticated Timestamp",
      last_authenticated_entity as "Last Authenticated Entity",
      last_authenticated_region as "Last Authenticated Region",
      arn as "ARN"
    from
      aws_iam_access_advisor,
      aws_iam_user
    where
      principal_arn = arn
      and coalesce(last_authenticated, now() - '400 days' :: interval ) < now() - '${var.aws_iam_user_excessive_privilege_report_threshold_in_days} days' :: interval  -- should use the threshold value...
    order by
      name;
  EOQ
}