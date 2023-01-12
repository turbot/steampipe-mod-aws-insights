dashboard "iam_group_dashboard" {

  title         = "AWS IAM Group Dashboard"
  documentation = file("./dashboards/iam/docs/iam_group_dashboard.md")


  tags = merge(local.iam_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.iam_group_count
      width = 2
    }

    # Assessments
    card {
      query = query.iam_groups_without_users_count
      width = 2
    }

    card {
      query = query.iam_groups_with_inline_policy_count
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Groups Without Users"
      query = query.iam_groups_without_users
      type  = "donut"
      width = 3

      series "count" {
        point "with users" {
          color = "ok"
        }
        point "no users" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Inline Policies"
      query = query.iam_groups_with_inline_policy
      type  = "donut"
      width = 3

      series "count" {
        point "no inline policies" {
          color = "ok"
        }
        point "with inline policies" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Groups by Account"
      query = query.iam_groups_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Groups by Path"
      query = query.iam_groups_by_path
      type  = "column"
      width = 4
    }

    chart {
      title = "Groups by Age"
      query = query.iam_groups_by_creation_month
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "iam_group_count" {
  sql = <<-EOQ
    select count(*) as "Groups" from aws_iam_group;
  EOQ
}

query "iam_groups_without_users_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Without Users' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_group
    where
      users is null;
  EOQ
}

query "iam_groups_with_inline_policy_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'With Inline Policies' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_group
    where
      jsonb_array_length(inline_policies) > 0;
  EOQ
}

# Assessment Queries

query "iam_groups_without_users" {
  sql = <<-EOQ
    with groups_without_users as (
      select
        arn,
        case
          when users is null then 'no users'
          else 'with users'
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

query "iam_groups_with_inline_policy" {
  sql = <<-EOQ
    with group_inline_compliance as (
      select
        arn,
        case
          when jsonb_array_length(inline_policies) > 0 then 'with inline policies'
          else 'no inline policies'
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

# Analysis Queries

query "iam_groups_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(g.*) as "total"
    from
      aws_iam_group as g,
      aws_account as a
    where
      a.account_id = g.account_id
    group by
      a.title
    order by 
      count(g.*) desc;
  EOQ
}

query "iam_groups_by_path" {
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

query "iam_groups_by_creation_month" {
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
