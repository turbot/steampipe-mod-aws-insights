edge "iam_group_to_iam_policy" {
  title = "attaches"

  sql = <<-EOQ
    select
      arn as from_id,
      policy_arn as to_id
    from
      aws_iam_group,
      jsonb_array_elements_text(attached_policy_arns) as policy_arn
    where
      arn = $1;
  EOQ

  param "iam_group_arns" {}

}

edge "iam_group_to_iam_user" {
  title = "has member"

  sql = <<-EOQ
    select
      arn as from_id,
      member ->> 'Arn' as to_id
    from
    aws_iam_group,
    jsonb_array_elements(users) as member
  where
    arn = any($1);
  EOQ

  param "iam_group_arns" {}
}

edge "iam_group_to_inline_policy" {
  title = "inline policy"

  sql = <<-EOQ
    select
      g.arn as from_id,
      concat(g.arn, ':inline_', i ->> 'PolicyName') as to_id
    from
      aws_iam_group as g,
      jsonb_array_elements(inline_policies_std) as i
    where
      g.arn = any($1)
  EOQ

  param "iam_group_arns" {}
}

edge "iam_instance_profile_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      iam_instance_profile_arn as from_id,
      arn as to_id,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn
      ) as properties
    from
      aws_iam_role,
      jsonb_array_elements_text(instance_profile_arns) as iam_instance_profile_arn
    where
      arn = any($1);
  EOQ

  param "iam_role_arns" {}
}

edge "iam_policy_globbed_notaction" {

  sql = <<-EOQ

    select
      distinct on (a.action)
      concat('action:', a.action) as to_id,
      concat('statement:', i) as from_id,
      lower(t.stmt ->> 'Effect') as category,
      t.stmt ->> 'Effect' as title
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(t.stmt -> 'NotAction') as action_glob,
      aws_iam_action as a
    where
      a.action not like glob(action_glob)
  EOQ

  param "iam_policy_stds" {}
}

edge "iam_policy_statement" {
  title = "statement"

  sql = <<-EOQ

    select
      distinct on (p.arn,i)
      p.arn as from_id,
      concat('statement:', i) as to_id
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') with ordinality as t(stmt,i)
    where
      p.arn = any($1)
  EOQ

  param "iam_policy_arns" {}
}

edge "iam_policy_statement_action" {
  //title = "allows"
  sql = <<-EOQ

    select
      --distinct on (p.arn,action)
      concat('action:', action) as to_id,
      concat('statement:', i) as from_id,
      lower(t.stmt ->> 'Effect') as title,
      lower(t.stmt ->> 'Effect') as category
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(t.stmt -> 'Action') as action
  EOQ

  param "iam_policy_stds" {}
}

edge "iam_policy_statement_condition" {
  title = "condition"
  sql   = <<-EOQ

    select
      concat('statement:', i, ':condition:', condition.key) as to_id,
      concat('statement:', i) as from_id
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "iam_policy_stds" {}
}

edge "iam_policy_statement_condition_key" {
  title = "all of"
  sql   = <<-EOQ
    select
      concat('statement:', i, ':condition:', condition.key, ':', condition_key.key  ) as to_id,
      concat('statement:', i, ':condition:', condition.key) as from_id
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition,
      jsonb_each(condition.value) as condition_key
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "iam_policy_stds" {}
}

edge "iam_policy_statement_condition_key_value" {
  title = "any of"
  sql   = <<-EOQ
    select
      concat('statement:', i, ':condition:', condition.key, ':', condition_key.key, ':', condition_value  ) as to_id,
      concat('statement:', i, ':condition:', condition.key, ':', condition_key.key  ) as from_id
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

edge "iam_policy_statement_notaction" {
  sql = <<-EOQ

    select
      --distinct on (p.arn,notaction)
      concat('action:', notaction) as to_id,
      concat('statement:', i) as from_id,
      concat(lower(t.stmt ->> 'Effect'), ' not action') as title,
      lower(t.stmt ->> 'Effect') as category
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(t.stmt -> 'NotAction') as notaction
  EOQ

  param "iam_policy_stds" {}
}

edge "iam_policy_statement_notresource" {
  title = "not resource"

  sql = <<-EOQ
    select
      concat('action:', coalesce(action, notaction)) as from_id,
      notresource as to_id,
      lower(stmt ->> 'Effect') as category
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i)
      left join jsonb_array_elements_text(stmt -> 'Action') as action on true
      left join jsonb_array_elements_text(stmt -> 'NotAction') as notaction on true
      left join jsonb_array_elements_text(stmt -> 'NotResource') as notresource on true
  EOQ

  param "iam_policy_stds" {}
}

edge "iam_policy_statement_resource" {
  title = "resource"

  sql = <<-EOQ
    select
      concat('action:', coalesce(action, notaction)) as from_id,
      resource as to_id,
      lower(stmt ->> 'Effect') as category
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i)
      left join jsonb_array_elements_text(stmt -> 'Action') as action on true
      left join jsonb_array_elements_text(stmt -> 'NotAction') as notaction on true
      left join jsonb_array_elements_text(stmt -> 'Resource') as resource on true
  EOQ

  param "iam_policy_stds" {}
}

edge "iam_role_to_iam_policy" {
  title = "attaches"

  sql = <<-EOQ
    select
      arn as from_id,
      policy_arn as to_id
    from
      aws_iam_role,
      jsonb_array_elements_text(attached_policy_arns) as policy_arn
    where
      arn = any($1);
  EOQ

  param "iam_role_arns" {}
}

edge "iam_role_trusted_aws" {
  title = "can assume"

  sql = <<-EOQ
    select
      arn as to_id,
      aws as from_id
    from
      aws_iam_role as r,
      jsonb_array_elements(assume_role_policy_std -> 'Statement') as s,
      jsonb_array_elements_text( (s -> 'Principal' ->> 'AWS')::jsonb ) as aws
    where
      r.arn = any($1);
  EOQ

  param "iam_role_arns" {}
}

edge "iam_role_trusted_federated" {
  title = "can assume"

  sql = <<-EOQ
    select
      arn as to_id,
      fed as from_id
    from
      aws_iam_role as r,
      jsonb_array_elements(assume_role_policy_std -> 'Statement') as s,
      jsonb_array_elements_text( (s -> 'Principal' ->> 'Federated')::jsonb ) as fed
    where
      r.arn = any($1);
  EOQ

  param "iam_role_arns" {}
}

edge "iam_role_trusted_service" {
  title = "can assume"

  sql = <<-EOQ
    select
      arn as to_id,
      svc as from_id
    from
      aws_iam_role as r,
      jsonb_array_elements(assume_role_policy_std -> 'Statement') as s,
      jsonb_array_elements_text( (s -> 'Principal' ->> 'Service')::jsonb ) as svc
    where
      r.arn = any($1);
  EOQ

  param "iam_role_arns" {}
}

edge "iam_user_to_iam_policy" {
  title = "attaches"

  sql = <<-EOQ
    select
      arn as from_id,
      policy_arn as to_id
    from
      aws_iam_user,
      jsonb_array_elements_text(attached_policy_arns) as policy_arn
    where
      arn = any($1);
  EOQ

  param "iam_user_arns" {}
}

edge "iam_user_to_inline_policy" {
  title = "inline policy"

  sql = <<-EOQ
    select
      u.arn as from_id,
      concat(u.arn, ':inline_', i ->> 'PolicyName') as to_id
    from
      aws_iam_user as u,
      jsonb_array_elements(inline_policies_std) as i
    where
      u.arn = any($1)
  EOQ

  param "iam_user_arns" {}
}

edge "iam_user_to_iam_access_key" {
  title = "access key"

  sql = <<-EOQ
    select
      u.arn as from_id,
      a.access_key_id as to_id
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
