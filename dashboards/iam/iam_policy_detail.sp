dashboard "aws_iam_policy_detail" {
  title         = "AWS IAM Policy Detail"
  documentation = file("./dashboards/iam/docs/iam_policy_detail.md")
  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "policy_arn" {
    title = "Select a policy:"
    query = query.aws_iam_policy_input
    width = 4
  }

  graph {
    type  = "graph"
    base  = graph.aws_graph_categories
    query = query.aws_iam_policy_relationships_graph
    args = {
      arn = self.input.policy_arn.value
    }
    category "aws_iam_policy" {}
  }
}

query "aws_iam_policy_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id
      ) as tags
    from
      aws_iam_policy
    order by
      title;
  EOQ
}

query "aws_iam_policy_relationships_graph" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      policy_id as id,
      name as title,
      'aws_iam_policy' as category,
      jsonb_build_object(
        'ARN', arn,
        'AWS Managed', is_aws_managed::text,
        'Attached', is_attached::text,
        'Create Date', create_date,
        'Account ID', account_id ) as properties
    from
      aws_iam_policy
    where
      arn = $1

    -- From IAM roles (node)
    union all
    select
      null as from_id,
      null as to_id,
      role_id as id,
      name as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', arn,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id ) as properties
    from
      aws_iam_role,
      jsonb_array_elements_text(attached_policy_arns) as arns
    where
      arns = $1

    -- From IAM roles (edge)
    union all
    select
      r.role_id as from_id,
      p.policy_id as to_id,
      null as id,
      'attached with' as title,
      'iam_role_to_iam_policy' as category,
      jsonb_build_object(
        'Account ID', r.account_id ) as properties
    from
      aws_iam_role as r,
      jsonb_array_elements_text(attached_policy_arns) as arns
    left join
      aws_iam_policy as p
      on p.arn = arns
    where
      p.arn = $1

     -- From IAM users (node)
    union all
    select
      null as from_id,
      null as to_id,
      u.name as id,
      u.name as title,
      'aws_iam_user' as category,
      jsonb_build_object(
        'ARN', u.arn,
        'path', path,
        'Create Date', create_date,
        'MFA Enabled', mfa_enabled::text,
        'Account ID', u.account_id ) as properties
    from
      aws_iam_user as u,
      jsonb_array_elements_text(attached_policy_arns) as arns
    where
      arns = $1

    -- From IAM users (edge)
    union all
    select
      u.name as from_id,
      p.policy_id as to_id,
      null as id,
      'attached with' as title,
      'iam_user_to_iam_policy' as category,
      jsonb_build_object(
        'Account ID', u.account_id ) as properties
    from
      aws_iam_user as u,
      jsonb_array_elements_text(attached_policy_arns) as arns,
      aws_iam_policy as p
    where
      p.arn = arns
      and p.arn = $1


    -- From IAM groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      g.name as id,
      g.name as title,
      'aws_iam_group' as category,
      jsonb_build_object(
        'ARN', arn,
        'Path', path,
        'Create Date', create_date,
        'Account ID', account_id ) as properties
    from
      aws_iam_group as g,
      jsonb_array_elements_text(attached_policy_arns) as arns
    where
      arns = $1

    -- From IAM groups (edge)
    union all
    select
      g.name as from_id,
      p.policy_id as to_id,
      null as id,
      'attached with' as title,
      'iam_group_to_iam_policy' as category,
      jsonb_build_object( 'Account ID', g.account_id ) as properties
    from
      aws_iam_group as g,
      jsonb_array_elements_text(attached_policy_arns) as arns,
      aws_iam_policy as p
    where
      p.arn = arns
      and p.arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}
