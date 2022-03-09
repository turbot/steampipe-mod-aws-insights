dashboard "aws_iam_user_dashboard" {

  title = "AWS IAM User Dashboard"
  documentation = file("./dashboards/iam/docs/iam_user_dashboard.md")

  tags = merge(local.iam_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.aws_iam_user_count.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_iam_user_no_mfa_count.sql
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
    title = "Assessments"

    chart {
      title = "MFA Status"
      sql   = query.aws_iam_users_by_mfa_enabled.sql
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Boundary Policy"
      sql   = query.aws_iam_users_by_boundary_policy.sql
      type  = "donut"
      width = 3

      series "count" {
        point "configured" {
          color = "ok"
        }
        point "not configured" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Directly Attached Policies"
      sql   = query.aws_iam_users_with_direct_attached_policy.sql
      type  = "donut"
      width = 3

      series "count" {
        point "unattached" {
          color = "ok"
        }
        point "attached" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Inline Policies"
      sql   = query.aws_iam_users_with_inline_policy.sql
      type  = "donut"
      width = 3

      series "count" {
        point "not associated" {
          color = "ok"
        }
        point "associated" {
          color = "alert"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Users by Account"
      sql   = query.aws_iam_users_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Users by Path"
      sql   = query.aws_iam_user_by_path.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Users by Age"
      sql   = query.aws_iam_user_by_creation_month.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "aws_iam_user_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Users' as label
    from
      aws_iam_user;
  EOQ
}

query "aws_iam_user_no_mfa_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'MFA Not Enabled' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
      not mfa_enabled;
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
      permissions_boundary_type is null or permissions_boundary_type = '';
  EOQ
}

query "aws_iam_users_with_direct_attached_policy_count" {
  sql = <<-EOQ
    select
      count(*) as value,
       'With Attached Policies' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
      jsonb_array_length(attached_policy_arns) > 0;
  EOQ
}

query "aws_iam_users_with_inline_policy_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'With Inline Policies' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
      jsonb_array_length(inline_policies) > 0;
  EOQ
}

# Assessment Queries

query "aws_iam_users_by_mfa_enabled" {
  sql = <<-EOQ
    with mfa_stat as (
      select
        case
          when mfa_enabled then 'enabled'
          else 'disabled'
        end as mfa_status
      from
        aws_iam_user
    )
    select
      mfa_status,
      count(*)
    from
      mfa_stat
    group by
      mfa_status;
  EOQ
}

query "aws_iam_users_by_boundary_policy" {
  sql = <<-EOQ
    select
      case
        when permissions_boundary_type is null or permissions_boundary_type = '' then 'not configured'
        else 'configured'
      end as policy_type,
      count(*)
    from
      aws_iam_user
    group by
      permissions_boundary_type;
  EOQ
}

query "aws_iam_users_with_direct_attached_policy" {
  sql = <<-EOQ
    with attached_compliance as (
      select
        arn,
        case
          when jsonb_array_length(attached_policy_arns) > 0 then 'attached'
          else 'unattached'
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
      has_attached;
  EOQ
}

query "aws_iam_users_with_inline_policy" {
  sql = <<-EOQ
    with inline_compliance as (
      select
        arn,
        case
          when jsonb_array_length(inline_policies) > 0 then 'associated'
          else 'not associated'
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
      has_inline;
  EOQ
}

# Analysis Queries

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
      count desc;
  EOQ
}

query "aws_iam_user_by_path" {
  sql = <<-EOQ
    select
      path,
      count(name) as "total"
    from
      aws_iam_user
    group by
      path;
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
