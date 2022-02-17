query "aws_iam_role_count" {
  sql = <<-EOQ
    select count(*) as "Roles" from aws_iam_role
  EOQ
}

query "aws_iam_roles_with_inline_policy_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Roles with Inline Policies' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_role
    where
      jsonb_array_length(inline_policies) > 0
  EOQ
}

query "aws_iam_roles_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_iam_role as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc
  EOQ
}


query "aws_iam_roles_by_path" {
  sql = <<-EOQ
    select
      path,
      count(name) as "total"
    from
      aws_iam_role
    group by
      path
    order by
      total desc
  EOQ
}

query "aws_iam_roles_with_inline_policy" {
  sql = <<-EOQ
    with roles_inline_compliance as (
      select
        arn,
        case
          when jsonb_array_length(inline_policies) > 0 then 'With Inline Policies'
          else 'OK'
        end as has_inline
      from
        aws_iam_role
      )
      select
        has_inline,
        count(*)
      from
        roles_inline_compliance
      group by
        has_inline
  EOQ
}

query "aws_iam_roles_allow_all_action" {
  sql = <<-EOQ
    with roles_allow_all_actions as (
      select
        r.name as role_name,
        r.account_id as account_id,
        p.name as policy_name
      from
        aws_iam_role as r,
        jsonb_array_elements_text(r.attached_policy_arns) as policy_arn,
        aws_iam_policy as p,
        jsonb_array_elements(p.policy_std -> 'Statement') as stmt,
        jsonb_array_elements_text(stmt -> 'Action') as action
      where
        policy_arn = p.arn
        and stmt ->> 'Effect' = 'Allow'
        and action = '*'
      order by
        r.name
    )
    select
      a.title as "account",
      count(role_name)::numeric as "Allows * Actions"
    from
      roles_allow_all_actions as c,
      aws_account as a
    where
      a.account_id = c.account_id
    group by
      account
    order by
      account
  EOQ
}

query "aws_iam_roles_with_direct_attached_policy" {
  sql = <<-EOQ
    with role_attached_compliance as (
      select
        arn,
        case
          when jsonb_array_length(attached_policy_arns) > 0 then 'With Attached Policies'
          else 'OK'
        end as has_attached
      from
        aws_iam_role
      )
      select
        has_attached,
        count(*)
      from
        role_attached_compliance
      group by
        has_attached
  EOQ
}

query "aws_iam_roles_by_creation_month" {
  sql = <<-EOQ
    with roles as (
      select
        title,
        create_date,
        to_char(create_date,
          'YYYY-MM') as creation_month
      from
        aws_iam_role
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
                from roles)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    roles_by_month as (
      select
        creation_month,
        count(*)
      from
        roles
      group by
        creation_month
    )
    select
      months.month,
      roles_by_month.count
    from
      months
      left join roles_by_month on months.month = roles_by_month.creation_month
    order by
      months.month desc;
  EOQ
}

dashboard "aws_iam_role_dashboard" {

  title = "AWS IAM Role Dashboard"

  container {
    card {
      sql   = query.aws_iam_role_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_roles_with_inline_policy_count.sql
      width = 2
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "Roles by Account"
      sql   = query.aws_iam_roles_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Roles by Path"
      sql   = query.aws_iam_roles_by_path.sql
      type  = "column"
      width = 3
    }
  }

  container {
    title = "Assesments"

    chart {
      title = "Inline Policy"
      sql   = query.aws_iam_roles_with_inline_policy.sql
      type  = "donut"
      width = 3
    }

    chart {
      title = "Direct Attached Policy"
      sql   = query.aws_iam_roles_with_direct_attached_policy.sql
      type  = "donut"
      width = 3
    }

    chart {
      title = "Allow All Actions"
      sql   = query.aws_iam_roles_allow_all_action.sql
      type  = "donut"
      width = 3
    }
  }

  container {
    title = "Resources by Age"

    chart {
      title = "Roles by Creation Month"
      sql   = query.aws_iam_roles_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest Roles"
      width = 4

      sql = <<-EOQ
        select
          title as "role",
          (current_date - create_date)::text as "Age in Days",
          account_id as "Account"
        from
          aws_iam_role
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest Roles"
      width = 4

      sql = <<-EOQ
        select
          title as "role",
          current_date - create_date as "Age in Days",
          account_id as "Account"
        from
          aws_iam_role
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }
  }
}

