dashboard "iam_role_report" {

  title         = "AWS IAM Role Report"
  documentation = file("./dashboards/iam/docs/iam_role_dashboard.md")

  tags = merge(local.iam_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.iam_role_count
      width = 2
    }

    # Assessments
    card {
      query = query.iam_roles_with_inline_policy_count
      width = 2
    }

    card {
      query = query.iam_roles_without_direct_attached_policy_count
      width = 2
    }

    card {
      query = query.iam_roles_allow_all_action_count
      width = 2
    }

    card {
      query = query.iam_role_no_boundary_count
      width = 2
    }

    card {
      query = query.iam_role_allows_assume_role_to_all_principal_count
      width = 2
    }

  }

  container {

    title = "Details"

    container {
      table {
        title = "Overview"
        query = query.iam_role_report
      }
    }

  }
}

query "iam_role_report" {
  sql = <<-EOQ
    with roles_allow_all_actions as (
      select
        r.name as role_name,
        r.create_date as create_date,
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
    ), all_action as (
    select
      *, 
      case
        when c.role_name is not null then 'allows all actions'
        else 'limited actions' end as allow_all_actions
    from
      aws_iam_role as r
      left join roles_allow_all_actions as c on c.role_name = r.name
    ) , roles_allow_all_principals as (
      select
      *, 
      case
        when principal = '*' and stmt ->> 'Effect' = 'Allow' then 'allows all principals'
        else 'limited principals' end as allow_all_principals
      from
        all_action role,
        jsonb_array_elements(role.assume_role_policy_std -> 'Statement') as stmt,
        jsonb_array_elements_text(stmt -> 'Principal' -> 'AWS') as principal
    )
    select
      a.name,
      a.arn,
      a.description,
      a.max_session_duration,
      a.permissions_boundary_arn,
      a.role_last_used_date,
      a.tags -> 'Owner' as tag_owner,
      a.title, 
      a.allow_all_actions,
      a.allow_all_principals
    from
      roles_allow_all_principals a
  EOQ
}

