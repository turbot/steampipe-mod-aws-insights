query "aws_iam_role_count" {
  sql = <<-EOQ
    select count(*) as "Roles" from aws_iam_role
  EOQ
}

query "aws_iam_role_by_account" {
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


query "aws_iam_role_by_path" {
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

query "aws_iam_role_without_inline_policies_by_account" {
  sql = <<-EOQ
    select
       a.title as "account",
       count(name)::numeric as "Roles Without Inline Policies"
    from
      aws_iam_user as c,
      aws_account as a
    where
      a.account_id = c.account_id and inline_policies is null
    group by
      account
    order by
      account
  EOQ
}

query "aws_iam_role_allow_all_action_by_account" {
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
      count(role_name)::numeric as "Roles Allows All Actions"
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

query "aws_iam_role_without_any_attached_policy_by_account" {
  sql = <<-EOQ
    select
       a.title as "account",
       count(name)::numeric as "Roles Without Attached Policies"
    from
      aws_iam_role as c,
      aws_account as a
    where
      a.account_id = c.account_id and attached_policy_arns is null
    group by
      account
    order by
      account
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

report "aws_iam_role_dashboard" {

  title = "AWS IAM Role Dashboard"

  container {
    card {
      sql   = query.aws_iam_role_count.sql
      width = 2
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "Roles by Account"
      sql   = query.aws_iam_role_by_account.sql
      type  = "column"
      width = 6
    }

    chart {
      title = "Roles by Path"
      sql   = query.aws_iam_role_by_path.sql
      type  = "column"
      width = 6
    }
  }

  container {
    title = "Assesments"

    chart {
      title = "Roles Without inline policies by Account"
      sql   = query.aws_iam_role_without_inline_policies_by_account.sql
      type  = "donut"
      width = 4
    }
    chart {
      title = "Roles that Allow All Actions by Account"
      sql   = query.aws_iam_role_allow_all_action_by_account.sql
      type  = "donut"
      width = 4
    }
    chart {
      title = "Roles Without Any Attached Policy"
      sql   = query.aws_iam_role_without_any_attached_policy_by_account.sql
      type  = "donut"
      width = 4
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

