dashboard "aws_iam_group_dashboard" {

  title = "AWS IAM Group Dashboard"

  tags = merge(local.iam_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.aws_iam_group_count.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_iam_groups_without_users_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_groups_with_inline_policy_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_groups_with_administrator_policy_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Groups Without Users"
      sql   = query.aws_iam_groups_without_users.sql
      type  = "donut"
      width = 3

      series "count" {
        point "with users" {
          color = "ok"
        }
        point "without users" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Inline Policy"
      sql   = query.aws_iam_groups_with_inline_policy.sql
      type  = "donut"
      width = 3

      series "count" {
        point "unconfigured" {
          color = "ok"
        }
        point "configured" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Administrator Access Policy"
      sql   = query.aws_iam_groups_with_administrator_policy.sql
      type  = "donut"
      width = 3

      series "count" {
        point "unconfigured" {
          color = "ok"
        }
        point "configured" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Groups by Account"
      sql   = query.aws_iam_groups_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Groups by Path"
      sql   = query.aws_iam_groups_by_path.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Groups by Age"
      sql   = query.aws_iam_groups_by_creation_month.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "aws_iam_group_count" {
  sql = <<-EOQ
    select count(*) as "Groups" from aws_iam_group;
  EOQ
}

query "aws_iam_groups_without_users_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Groups Without Users' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_group
    where
      users is null;
  EOQ
}

query "aws_iam_groups_with_inline_policy_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Groups With Inline Policies' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_group
    where
      jsonb_array_length(inline_policies) > 0;
  EOQ
}

query "aws_iam_groups_with_administrator_policy_count" {
  sql = <<-EOQ
    with groups_having_admin_access as
    (
      select
        name,
        attached_policy_arns,
        case
          when
            attached_policy_arns @> ('["arn:' || partition || ':iam::aws:policy/AdministratorAccess"]')::jsonb
          then
            'With Administrator Policy'
          else
            'OK'
        end
        as has_administrator_policy
      from
        aws_iam_group
    )
    select
      count(*) as value,
      'Groups With Administrator Policy' as label,
      case when count(*) > 1 then 'alert' else 'ok' end as type
    from
      groups_having_admin_access
    where
      has_administrator_policy = 'With Administrator Policy';
  EOQ
}

# Assessment Queries

query "aws_iam_groups_without_users" {
  sql = <<-EOQ
    with groups_without_users as (
      select
        arn,
        case
          when users is null then 'without_users'
          else 'with_users'
        end as has_users
      from
        aws_iam_group
      )
      select
        has_users,
        count(*)
      from
        groups_without_users
      group by
        has_users;
  EOQ
}

query "aws_iam_groups_with_inline_policy" {
  sql = <<-EOQ
    with group_inline_compliance as (
      select
        arn,
        case
          when jsonb_array_length(inline_policies) > 0 then 'configured'
          else 'unconfigured'
        end as has_inline
      from
        aws_iam_group
      )
      select
        has_inline,
        count(*)
      from
        group_inline_compliance
      group by
        has_inline;
  EOQ
}

query "aws_iam_groups_with_administrator_policy" {
  sql = <<-EOQ
    with groups_having_admin_access as
    (
      select
        name,
        attached_policy_arns,
        case
          when
            attached_policy_arns @> ('["arn:' || partition || ':iam::aws:policy/AdministratorAccess"]')::jsonb
          then
            'configured'
          else
            'unconfigured'
        end
        as has_administrator_policy
      from
        aws_iam_group
    )
    select
      has_administrator_policy,
      count(*)
    from
      groups_having_admin_access
    group by
      has_administrator_policy;
  EOQ
}

# Analysis Queries

query "aws_iam_groups_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(g.*) as "total"
    from
      aws_iam_group as g,
      aws_account as a
    where
      a.account_id = g.account_id
    group by
      account
    order by count(g.*) desc;
  EOQ
}

query "aws_iam_groups_by_path" {
  sql = <<-EOQ
    select
      path,
      count(name) as "total"
    from
      aws_iam_group
    group by
      path;
  EOQ
}

query "aws_iam_groups_by_creation_month" {
  sql = <<-EOQ
    with groups as (
      select
        title,
        create_date,
        to_char(create_date,
          'YYYY-MM') as creation_month
      from
        aws_iam_group
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
              from groups)),
          date_trunc('month',
            current_date),
          interval '1 month') as d
    ),
    groups_by_month as (
      select
        creation_month,
        count(*)
      from
        groups
      group by
        creation_month
    )
    select
      months.month,
      groups_by_month.count
    from
      months
      left join groups_by_month on months.month = groups_by_month.creation_month
    order by
      months.month;
  EOQ
}
