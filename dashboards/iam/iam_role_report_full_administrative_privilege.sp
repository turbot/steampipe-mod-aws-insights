dashboard "aws_iam_role_full_administrative_privilege_report" {

  title = "AWS IAM Role Full Administrative Privilege Report"

  tags = merge(local.iam_common_tags, {
    type     = "Report"
    category = "Permissions"
  })

  container {

    card {
      sql   = query.aws_iam_role_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_roles_allow_all_action_count.sql
      width = 2
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    sql = query.aws_iam_roles_allow_all_actions.sql
  }

}

query "aws_iam_roles_allow_all_actions" {
  sql = <<-EOQ
    with roles_that_allow_all_actions as (
      select
        r.name as "role_name",
        r.create_date,
        p.name as "policy_name",
        r.account_id
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
      role.role_name as "Role",
      role.create_date as "Created Date",
      role.policy_name as "Policy",
      a.title as "Account",
      role.account_id as "Account ID"
    from
      roles_that_allow_all_actions as role,
      aws_account as a
    where
      a.account_id = role.account_id
    order by
      role.role_name;
  EOQ
}
