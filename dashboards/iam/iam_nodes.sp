node "iam_group" {
  category = category.iam_group

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'Path', path,
        'Create Date', create_date,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_group
    where
      arn = any($1);
  EOQ

  param "iam_group_arns" {}
}

node "iam_group_inline_policy" {
  category = category.iam_inline_policy

  sql = <<-EOQ
    select
      concat(g.arn, ':inline_', i ->> 'PolicyName') as id,
      i ->> 'PolicyName' as title,
      jsonb_build_object(
        'PolicyName', i ->> 'PolicyName',
        'Type', 'Inline Policy'
      ) as properties
    from
      aws_iam_group as g,
      jsonb_array_elements(inline_policies_std) as i
    where
      g.arn = any($1)
  EOQ

  param "iam_group_arns" {}
}

node "iam_role" {
  category = category.iam_role

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_role
    where
      arn = any($1 ::text[]);
  EOQ

  param "iam_role_arns" {}
}

node "iam_policy" {
  category = category.iam_policy

  sql = <<-EOQ
    select
      distinct on (arn)
      arn as id,
      name as title,
      'aws_iam_policy' as category,
      jsonb_build_object(
        'ARN', arn,
        'AWS Managed', is_aws_managed::text,
        'Attached', is_attached::text,
        'Create Date', create_date,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_policy
    where
      arn = any($1);
  EOQ

  param "iam_policy_arns" {}
}

node "iam_policy_statement" {
  category = category.iam_policy_statement

  sql = <<-EOQ
    select
      concat('statement:', i) as id,
      coalesce (
        t.stmt ->> 'Sid',
        concat('[', i::text, ']')
        ) as title
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i)
  EOQ

  param "iam_policy_stds" {}
}

node "iam_policy_statement_condition" {
  category = category.iam_policy_condition

  sql = <<-EOQ
    select
      condition.key as title,
      concat('statement:', i, ':condition:', condition.key  ) as id,
      condition.value as properties
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "iam_policy_stds" {}
}

node "iam_policy_statement_condition_key" {
  category = category.iam_policy_condition_key

  sql = <<-EOQ
    select
      condition_key.key as title,
      concat('statement:', i, ':condition:', condition.key, ':', condition_key.key  ) as id,
      condition_key.value as properties
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition,
      jsonb_each(condition.value) as condition_key
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "iam_policy_stds" {}
}

node "iam_policy_statement_condition_key_value" {
  category = category.iam_policy_condition_value

  sql = <<-EOQ
    select
      condition_value as title,
      concat('statement:', i, ':condition:', condition.key, ':', condition_key.key, ':', condition_value  ) as id
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition,
      jsonb_each(condition.value) as condition_key,
      jsonb_array_elements_text(condition_key.value) as condition_value
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "iam_policy_stds" {}
}

node "iam_policy_statement_action_notaction" {
  category = category.iam_policy_action

  sql = <<-EOQ

    select
      concat('action:', action) as id,
      action as title
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(coalesce(t.stmt -> 'Action','[]'::jsonb) || coalesce(t.stmt -> 'NotAction','[]'::jsonb)) as action
  EOQ

  param "iam_policy_stds" {}
}

node "iam_policy_statement_resource_notresource" {
  category = category.iam_policy_resource

  sql = <<-EOQ
    select
      resource as id,
      resource as title
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(coalesce(t.stmt -> 'Action','[]'::jsonb) || coalesce(t.stmt -> 'NotAction','[]'::jsonb)) as action,
      jsonb_array_elements_text(coalesce(t.stmt -> 'Resource','[]'::jsonb) || coalesce(t.stmt -> 'NotResource','[]'::jsonb)) as resource
  EOQ

  param "iam_policy_stds" {}
}

node "iam_policy_globbed_notaction" {
  category = category.iam_policy_notaction

  sql = <<-EOQ
    select
      distinct on (a.action)
      concat ('action:', a.action) as id,
      a.action as title
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') as stmt,
      jsonb_array_elements_text(stmt -> 'NotAction') as action_glob,
      aws_iam_action as a
    where
      a.action not like glob(action_glob)
  EOQ

  param "iam_policy_stds" {}
}

node "iam_user" {
  category = category.iam_user

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'Path', path,
        'Create Date', create_date,
        'MFA Enabled', mfa_enabled::text,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_user
    where
      arn = any($1);
  EOQ

  param "iam_user_arns" {}
}

node "iam_user_inline_policy" {
  category = category.iam_inline_policy

  sql = <<-EOQ
    select
      concat(u.arn, ':inline_', i ->> 'PolicyName') as id,
      i ->> 'PolicyName' as title,
      jsonb_build_object(
        'PolicyName', i ->> 'PolicyName',
        'Type', 'Inline Policy'
      ) as properties
    from
      aws_iam_user as u,
      jsonb_array_elements(inline_policies_std) as i
    where
      u.arn = any($1)
  EOQ

  param "iam_user_arns" {}
}

node "iam_user_access_key" {
  category = category.iam_access_key

  sql = <<-EOQ
    select
      a.access_key_id as id,
      a.access_key_id as title,
      jsonb_build_object(
        'Key Id', a.access_key_id,
        'Status', a.status,
        'Create Date', a.create_date,
        'Last Used Date', a.access_key_last_used_date,
        'Last Used Service', a.access_key_last_used_service,
        'Last Used Region', a.access_key_last_used_region
      ) as properties
    from
      aws_iam_access_key as a,
      aws_iam_user as u
    where
      u.name = a.user_name
      and u.account_id = a.account_id
      and u.arn  = any($1);
  EOQ

  param "iam_user_arns" {}
}

node "iam_role_trusted_service" {
  category = category.iam_service_principal

  sql = <<-EOQ
    select
      svc as id,
      svc as title,
      jsonb_build_object(
        'ARN', svc,
        'Principal Type', 'Service'
      ) as properties
    from
      aws_iam_role as r,
      jsonb_array_elements(assume_role_policy_std -> 'Statement') as s,
      jsonb_array_elements_text( (s -> 'Principal' ->> 'Service')::jsonb ) as svc
    where
      r.arn = any($1);
  EOQ

  param "iam_role_arns" {}
}


node "iam_role_trusted_federated" {
  category = category.iam_federated_principal

  sql = <<-EOQ
    select
      fed as id,
      fed as title,
      jsonb_build_object(
        'ARN', fed,
        'Principal Type', 'Federated'
      ) as properties
    from
      aws_iam_role as r,
      jsonb_array_elements(assume_role_policy_std -> 'Statement') as s,
      jsonb_array_elements_text( (s -> 'Principal' ->> 'Federated')::jsonb ) as fed
    where
      r.arn = any($1);
  EOQ

  param "iam_role_arns" {}
}

node "iam_role_trusted_aws" {
  category = category.account

  sql = <<-EOQ
    select
      aws as id,
      concat(
        split_part(aws,':',5),
        ':',
        split_part(aws,':',6)
      ) as title,
      jsonb_build_object(
        'ARN', aws,
        'Principal Type', 'AWS'
      ) as properties
    from
      aws_iam_role as r,
      jsonb_array_elements(assume_role_policy_std -> 'Statement') as s,
      jsonb_array_elements_text( (s -> 'Principal' ->> 'AWS')::jsonb ) as aws
   where
      r.arn = any($1);
  EOQ

  param "iam_role_arns" {}
}