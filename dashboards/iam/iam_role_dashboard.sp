query "aws_iam_role_count" {
  sql = <<-EOQ
    select count(*) as "Roles" from aws_iam_role;
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
      jsonb_array_length(inline_policies) > 0;
  EOQ
}

query "aws_iam_roles_without_direct_attached_policy_count" {
  sql = <<-EOQ
    select
      count(*) as value,
       'Roles without Attached Policies' as label,
      case when count(*) > 0 then 'alert' else 'ok' end as type
    from
      aws_iam_role
    where
      attached_policy_arns is null;
  EOQ
}

query "aws_iam_roles_allow_all_action_count" {
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
      count(role_name)::numeric as value,
      'Roles Allows All Actions' as label,
      case when count(*) > 0 then 'alert' else 'ok' end as type
    from
      roles_allow_all_actions;
  EOQ
}

query "aws_iam_role_no_boundary_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Roles with No Boundary Policy' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_role
    where
      permissions_boundary_type is null or permissions_boundary_type = '';
  EOQ
}

query "aws_iam_role_allows_assume_role_to_all_principal_count" {
  sql = <<-EOQ
    with roles_can_be_assumed_anonymously as (
      select
        name,
        stmt -> 'Principal',
        Principal
      from
        aws_iam_role role,
        jsonb_array_elements(role.assume_role_policy_std -> 'Statement') as stmt,
        jsonb_array_elements_text(stmt -> 'Principal' -> 'AWS') as principal
      where
        principal = '*'
        and stmt ->> 'Effect' = 'Allow'
    )
    select
      count(distinct name) as value,
      'Allows All Principals To Assume Role' as label,
      case when count(distinct name) > 0 then 'alert' else 'ok' end as type
    from
      roles_can_be_assumed_anonymously;
  EOQ
}

# Assessment
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
        has_inline;
  EOQ
}

query "aws_iam_roles_with_direct_attached_policy" {
  sql = <<-EOQ
    with role_attached_compliance as (
      select
        arn,
        case
          when jsonb_array_length(attached_policy_arns) > 0 then 'With Attached Policies'
          else 'Alert'
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
        has_attached;
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
      account;
  EOQ
}

query "aws_iam_roles_by_boundary_policy" {
  sql = <<-EOQ
    select
      case
        when permissions_boundary_type is null or permissions_boundary_type = '' then 'Not Configured'
        else 'Configured'
      end as policy_type,
      count(*)
    from
      aws_iam_role
    group by
      permissions_boundary_type;
  EOQ
}

# Analysis
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
    order by count(i.*) desc;
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
      total desc;
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
      months.month;
  EOQ
}

dashboard "aws_iam_role_dashboard" {

  title = "AWS IAM Role Dashboard"

  container {

    # Analysis
    card {
      sql   = query.aws_iam_role_count.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_iam_roles_with_inline_policy_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_roles_without_direct_attached_policy_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_roles_allow_all_action_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_role_no_boundary_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_role_allows_assume_role_to_all_principal_count.sql
      icon  = "shield-check"
      width = 2
    }

  }

  container {
    title = "Assessments"

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

    chart {
      title = "Boundary Policy"
      sql   = query.aws_iam_roles_by_boundary_policy.sql
      type  = "donut"
      width = 3
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Roles by Account"
      sql   = query.aws_iam_roles_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Roles by Path"
      sql   = query.aws_iam_roles_by_path.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Roles by Age"
      sql   = query.aws_iam_roles_by_creation_month.sql
      type  = "column"
      width = 4
    }

  }

}
