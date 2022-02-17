query "aws_iam_user_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Total Users' as label
    from
      aws_iam_user
  EOQ
}

query "aws_iam_user_mfa_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'MFA Not Enabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
      not mfa_enabled
  EOQ
}




query "aws_iam_user_no_boundary_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'No Boundary Policy' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
      permissions_boundary_type is null or permissions_boundary_type = ''
  EOQ
}



###
query "aws_iam_users_by_account" {
  sql = <<-EOQ
    select
      a.title,
      count(*)
    from
      aws_iam_user as u,
      aws_account as a
    where
      u.account_id = a.account_id
    group by
      a.title
    order by
      count desc
  EOQ
}


####

query "aws_iam_users_by_mfa_enabled" {
  sql = <<-EOQ
    with mfa as (
      select
        case when mfa_enabled then 'Enabled' else 'Disabled' end as mfa_status
      from
        aws_iam_user
    )
    select
      mfa_status,
      count(mfa_status)
    from
      mfa
    group by
      mfa_status
  EOQ
}


query "aws_iam_users_by_boundary_policy" {
  sql = <<-EOQ
    select
      case
        when permissions_boundary_type is null or permissions_boundary_type = '' then 'Not Configured'
        else 'Configured'
      end as policy_type,
      count(*)
    from
      aws_iam_user
    group by
      permissions_boundary_type
  EOQ
}


query "aws_iam_users_with_direct_attached_policy_count" {
  sql = <<-EOQ
    select
      count(*) as value,
       'Users with Attached Policies' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
      jsonb_array_length(attached_policy_arns) > 0
  EOQ
}

query "aws_iam_users_with_inline_policy_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Users with Inline Policies' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
      jsonb_array_length(inline_policies) > 0
  EOQ
}


query "aws_iam_users_with_direct_attached_policy" {
  sql = <<-EOQ
    with attached_compliance as (
      select
        arn,
        case
          when jsonb_array_length(attached_policy_arns) > 0 then 'With Attached Policies'
          else 'OK'
        end as has_attached
      from
        aws_iam_user
      )
      select
        has_attached,
        count(*)
      from
        attached_compliance
      group by
        has_attached

  EOQ
}

query "aws_iam_users_with_inline_policy" {
  sql = <<-EOQ
    with inline_compliance as (
      select
        arn,
        case
          when jsonb_array_length(inline_policies) > 0 then 'With Inline Policies'
          else 'OK'
        end as has_inline
      from
        aws_iam_user
      )
      select
        has_inline,
        count(*)
      from
        inline_compliance
      group by
        has_inline
  EOQ
}


query "aws_iam_user_by_creation_month" {
  sql = <<-EOQ
    with users as (
      select
        title,
        create_date,
        to_char(create_date,
          'YYYY-MM') as creation_month
      from
        aws_iam_user
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(create_date)
                from users)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    users_by_month as (
      select
        creation_month,
        count(*)
      from
        users
      group by
        creation_month
    )
    select
      months.month,
      users_by_month.count
    from
      months
      left join users_by_month on months.month = users_by_month.creation_month
    order by
      months.month;
  EOQ
}


dashboard "aws_iam_user_dashboard" {
  title = "AWS IAM User Dashboard"


  container {


    # Analysis
    card {
      sql   = query.aws_iam_user_count.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_iam_user_mfa_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_user_no_boundary_count.sql
      width = 2
    }


    card {
      sql   = query.aws_iam_users_with_direct_attached_policy_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_users_with_inline_policy_count.sql
      width = 2
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Users by Account"
      sql   = query.aws_iam_users_by_account.sql
      type  = "column"
      width = 3
    }
  }


  container {
    title = "Assessments"

    chart {
      title = "MFA Status"
      sql   = query.aws_iam_users_by_mfa_enabled.sql
      type  = "donut"
      width = 3

      # series "mfa_status" {
      #   point "Enabled" {
      #     color = "ok"
      #   }
      #   point "Disabled" {
      #     color = "alert"
      #   }
      # }
    }


    chart {
      title = "Boundary Policy"
      sql   = query.aws_iam_users_by_boundary_policy.sql
      type  = "donut"
      width = 3
    }


    chart {
      title = "Direct Attached Policy"
      sql   = query.aws_iam_users_with_direct_attached_policy.sql
      type  = "donut"
      width = 3
    }


    chart {
      title = "Inline Policy"
      sql   = query.aws_iam_users_with_inline_policy.sql
      type  = "donut"
      width = 3
    }
  }



  container {
    title = "Resources by Age"

    chart {
      title = "User by Creation Month"
      sql   = query.aws_iam_user_by_creation_month.sql
      type  = "column"
      width = 4
      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest users"
      width = 4

      sql = <<-EOQ
        select
          title as "user",
          current_date - create_date as "Age in Days",
          account_id as "Account"
        from
          aws_iam_user
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest users"
      width = 4

      sql = <<-EOQ
        select
          title as "user",
          current_date - create_date as "Age in Days",
          account_id as "Account"
        from
          aws_iam_user
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }
  }

}
