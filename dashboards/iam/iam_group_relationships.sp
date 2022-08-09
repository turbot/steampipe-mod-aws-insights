dashboard "aws_iam_group_relationships" {
  title         = "AWS IAM Group Relationships"
  documentation = file("./dashboards/iam/docs/iam_group_relationships.md")
  tags = merge(local.iam_common_tags, {
    type = "Relationships"
  })

  input "group_arn" {
    title = "Select a group:"
    query = query.aws_iam_group_input
    width = 4
  }

  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_iam_group_graph_from_group
    args  = {
      arn = self.input.group_arn.value
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

  graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_iam_group_graph_to_group
    args  = {
      arn = self.input.group_arn.value
    }
    category "aws_iam_group" {
      href = "${dashboard.aws_iam_group_detail.url_path}?input.group_arn={{.properties.ARN | @uri}}"
    }

    category "aws_iam_user" {
      href = "${dashboard.aws_iam_user_detail.url_path}?input.user_arn={{.properties.ARN | @uri}}"
    }

    category "uses" {
      color = "green"
    }
  }
}

query "aws_iam_group_graph_from_group" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      group_id as id,
      name as title,
      'aws_iam_group' as category,
      jsonb_build_object(
        'ARN', arn,
        'Path', path,
        'Create Date', create_date,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_group
    where
      arn = $1

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
      arn in (select jsonb_array_elements_text(attached_policy_arns) from aws_iam_group where arn = $1)

    -- Attached Policies - Edges
    union all
    select
      r.group_id as from_id,
      p.policy_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Policy Name', p.name,
        'Policy ID', policy_id,
        'Account ID', p.account_id
      ) as properties
    from
      aws_iam_group as r,
      jsonb_array_elements_text(attached_policy_arns) as arns
      left join aws_iam_policy as p on p.arn = arns
    where
      r.arn = $1
    order by
      category,from_id,to_id;
  EOQ

  param "arn" {}
}

query "aws_iam_group_graph_to_group" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      group_id as id,
      name as title,
      'aws_iam_group' as category,
      jsonb_build_object(
        'ARN', arn,
        'Path', path,
        'Create Date', create_date,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_group
    where
      arn = $1

    -- User - nodes
    union all
    select
      null as from_id,
      null as to_id,
      u.name as id,
      u.name as title,
      'aws_iam_user' as category,
      jsonb_build_object(
        'ARN', u.arn,
        'path', Path,
        'Create Date', create_date,
        'MFA Enabled', mfa_enabled::text,
        'Account ID', u.account_id
      ) as properties
    from
      aws_iam_user as u,
      jsonb_array_elements(groups) as g
    where
      g ->> 'Arn' = $1

    -- User - Edges
    union all
    select
      u.name as from_id,
      g ->> 'GroupId' as from_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', u.arn,
        'Account ID', u.account_id
      ) as properties
    from
      aws_iam_user as u,
      jsonb_array_elements(groups) as g
    where
      g ->> 'Arn' = $1
    order by
      category,from_id,to_id
  EOQ

  param "arn" {}
}
