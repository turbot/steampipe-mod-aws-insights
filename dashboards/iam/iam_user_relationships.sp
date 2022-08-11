dashboard "aws_iam_user_relationships" {
  title         = "AWS IAM User Relationships"
  documentation = file("./dashboards/iam/docs/iam_user_relationships.md")
  tags = merge(local.iam_common_tags, {
    type = "Relationships"
  })

  input "user_arn" {
    title = "Select a user:"
    query = query.aws_iam_user_input
    width = 4
  }

  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_iam_user_graph_from_user
    args = {
      arn = self.input.user_arn.value
    }
    category "aws_iam_user" {
      href = "${dashboard.aws_iam_user_detail.url_path}?input.user_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/iam_user_dark.svg"))
    }

    category "aws_iam_group" {
      href = "${dashboard.aws_iam_group_detail.url_path}?input.group_arn={{.properties.ARN | @uri}}"
    }

    category "aws_iam_policy" {
      color = "blue"
    }

    category "uses" {
      color = "green"
    }
  }

}

query "aws_iam_user_graph_from_user" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      user_id as id,
      name as title,
      'aws_iam_user' as category,
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
      arn = $1

    -- Group - nodes
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
        'Account ID', account_id
      ) as properties
    from
      aws_iam_group as g,
      jsonb_array_elements(users) as u
    where
      u ->> 'Arn' = $1

    -- Group - Edges
    union all
    select
      u ->> 'UserId' as from_id,
      g.name as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', g.arn,
        'Account ID', g.account_id
      ) as properties
    from
      aws_iam_group as g,
      jsonb_array_elements(users) as u
    where
      u ->> 'Arn' = $1

    -- Attached Policies - nodes
    union all
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
        'Account ID', account_id
      ) as properties
    from
      aws_iam_policy
    where
      arn in (select jsonb_array_elements_text(attached_policy_arns) from aws_iam_user where arn = $1)

    -- Attached Policies - Edges
    union all
    select
      r.user_id as from_id,
      p.policy_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Policy Name', p.name,
        'AWS Managed', p.is_aws_managed
      ) as properties
    from
      aws_iam_user as r,
      jsonb_array_elements_text(attached_policy_arns) as arns
      left join aws_iam_policy as p on p.arn = arns
    where
      r.arn = $1
    order by
      category,from_id,to_id;
  EOQ

  param "arn" {}
}
