-- pgFormatter-ignore

with users as (
  select
    name,
    arn,
    inline_policies_std,
    attached_policy_arns,
    permissions_boundary_arn,
    groups,
    account_id
  from
    aws_iam_user
  order by
    name
),
groups as (
  select
    name,
    arn,
    inline_policies_std,
    attached_policy_arns,
    account_id
  from
    aws_iam_group
  order by
    name
),
policies as (
  select
    name,
    arn,
    policy_std,
    account_id
  from
    aws_iam_policy
  order by
    name
),
user_groups as (
  select
    distinct name,
    jsonb_array_elements(groups) ->> 'GroupName' as group,
    account_id
  from
    users
  order by
    name
),
user_group_inline_policies as (
  select
    user_groups.name,
    inline_policies_std as policy,
    groups.account_id
  from
    groups
    inner join user_groups on groups.name = user_groups.group and groups.account_id = user_groups.account_id
  order by
    user_groups.name
),
user_group_attached_policy_arns as (
  select
    distinct user_groups.name as user_name,
    user_groups.group as group_name,
    jsonb_array_elements_text(groups.attached_policy_arns) as policy_arn,
    groups.account_id
  from
    groups
    inner join user_groups on groups.name = user_groups.group and groups.account_id = user_groups.account_id
  order by
    user_groups.name
),
user_group_attached_policies as (
  select
    user_name,
    group_name,
    policy_arn,
    policy_std,
    p.account_id
  from
    user_group_attached_policy_arns ugapa
    inner join policies p on ugapa.policy_arn = p.arn and ugapa.account_id = p.account_id
  order by
    user_name
),
user_attached_policy_arns as (
  select
    distinct name,
    jsonb_array_elements_text(attached_policy_arns) as policy_arn,
    account_id
  from
    users
  order by
    name
),
user_attached_policies as (
  select
    uapa.name as user_name,
    policy_arn,
    policy_std,
    uapa.account_id
  from
    user_attached_policy_arns uapa
    inner join policies p on uapa.policy_arn = p.arn and uapa.account_id = p.account_id
  order by
    user_name
),
user_boundary_policies as (
  select
    u.name as name,
    u.permissions_boundary_arn as boundary_policy_arn,
    p.name as boundary_policy_name,
    p.policy_std as policy,
    u.account_id
  from
    users as u
    inner join policies as p on p.arn = u.permissions_boundary_arn and u.account_id = p.account_id
  where
    permissions_boundary_arn != ''
),
-- CHECKS
user_attached_policy_check as (
  select
    user_name as name,
    action,
    stmt ->> 'Effect' as effect,
    stmt ->> 'Condition' as conditions,
    'attached_policy_check' as check_type,
    account_id
  from
    user_attached_policies,
    jsonb_array_elements(policy_std -> 'Statement') as stmt,
    jsonb_array_elements_text(stmt -> 'Action') as action
  order by
    name,
    account_id
),
user_groups_inline_policy_check as (
  select
    name,
    action,
    stmt ->> 'Effect' as effect,
    stmt ->> 'Condition' as conditions,
    'user_groups_inline_policy_check' as check_type,
    account_id
  from
    user_group_inline_policies,
    jsonb_array_elements(policy) as inp,
    jsonb_array_elements(inp -> 'PolicyDocument' -> 'Statement') as stmt,
    jsonb_array_elements_text(stmt -> 'Action') as action
  order by
    name,
    account_id
),
user_inline_policy_check as (
  select
    name,
    action,
    s ->> 'Effect' as effect,
    s ->> 'Condition' as conditions,
    'user_inline_policy_check' as check_type,
    account_id
  from
    users,
    jsonb_array_elements(inline_policies_std) as inp,
    jsonb_array_elements(inp -> 'PolicyDocument' -> 'Statement') as s,
    jsonb_array_elements_text(s -> 'Action') as action
  order by
    name,
    account_id
),
user_groups_attached_policy_check as (
  select
    user_name as name,
    action,
    stmt ->> 'Effect' as effect,
    stmt ->> 'Condition' as conditions,
    'user_groups_attached_policy_check' as check_type,
    account_id
  from
    user_group_attached_policies,
    jsonb_array_elements(policy_std -> 'Statement') as stmt,
    jsonb_array_elements_text(stmt -> 'Action') as action
  order by
    name,
    account_id
),
user_permission_boundary_check as (
  select
    name,
    action,
    stmt ->> 'Effect' as effect,
    stmt ->> 'Condition' as conditions,
    'boundary_policy_check' as check_type,
    account_id
  from
    user_boundary_policies,
    jsonb_array_elements(policy -> 'Statement') as stmt,
    jsonb_array_elements_text(stmt -> 'Action') as action
  order by
    name,
    account_id
),
all_check as (
  select
    *
  from
    user_attached_policy_check

  UNION

  select
    *
  from
    user_inline_policy_check

  UNION

  select
    *
  from
    user_groups_inline_policy_check

  UNION

  select
    *
  from
    user_groups_attached_policy_check

  UNION

  select
    *
  from
    user_permission_boundary_check
),
checks as (
  select
    distinct name,
    action,
    effect,
    conditions,
    check_type,
    (
      effect = 'Deny'
      and 'iam:PutUserPolicy' ~* replace(action, '*', '.*')
    ) as deny_check,
    (
      effect = 'Allow'
      and 'iam:PutUserPolicy' ~* replace(action, '*', '.*')
    ) as allow_check,
    account_id
  from
    all_check
  order by
    check_type,
    account_id
),
users_denied as (
  select distinct
    name,
    account_id
  from
    checks
  where
    deny_check
  order by
    account_id,
    name
),
users_allowed as (
  select distinct
    name,
    account_id
  from
    checks
  where
    not deny_check
    and allow_check
  order by
    account_id,
    name
),
admin_users as (
  (
    select
      *
    from
      users_allowed
  )
  EXCEPT
    (
      select
        *
      from
        users_denied
    )
)
select
  count(*)
from
  admin_users;