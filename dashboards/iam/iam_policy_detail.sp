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

  container {

    card {
      width = 2
      query = query.aws_iam_policy_aws_managed
      args = {
        arn = self.input.policy_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_iam_policy_attached
      args = {
        arn = self.input.policy_arn.value
      }
    }
  }

  container {
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

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_iam_policy_overview
        args = {
          arn = self.input.policy_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_iam_policy_tags
        args = {
          arn = self.input.policy_arn.value
        }
      }

    }

    container {
      width = 6
      table {
        title = "Policy Statement"
        query = query.aws_iam_policy_statement
        args = {
          arn = self.input.policy_arn.value
        }

      }

    }

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

query "aws_iam_policy_aws_managed" {
  sql = <<-EOQ
    select
      case when is_aws_managed then 'AWS' else 'Customer' end as value,
      'Managed By' as label
    from
      aws_iam_policy
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_policy_attached" {
  sql = <<-EOQ
    select
      case when is_attached then 'Attached' else 'Detached' end as value,
      'Attachment Status' as label,
      case when is_attached then 'ok' else 'alert' end as type
    from
      aws_iam_policy
    where
      arn = $1
  EOQ

  param "arn" {}
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
      'iam role' as title,
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
      'iam user' as title,
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
      'iam group' as title,
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


query "aws_iam_policy_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      path as "Path",
      create_date as "Create Date",
      update_date as "Update Date",
      policy_id as "Policy ID",
      arn as "ARN",
      account_id as "Account ID"
    from
      aws_iam_policy
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_policy_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_iam_user,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key'
  EOQ

  param "arn" {}
}

query "aws_iam_policy_statement" {
  sql = <<-EOQ
    select
      p ->> 'Sid' as "Sid",
      p -> 'Action' as "Action",
      p ->> 'Effect' as "Effect",
      p -> 'Resource' as "Resource",
      p -> 'Condition' as "Condition"
    from
      aws_iam_policy,
      jsonb_array_elements(policy_std -> 'Statement') as p
    where
      arn = $1
  EOQ

  param "arn" {}
}
