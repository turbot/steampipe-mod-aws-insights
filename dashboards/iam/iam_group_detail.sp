dashboard "aws_iam_group_detail" {

  title         = "AWS IAM Group Detail"
  documentation = file("./dashboards/iam/docs/iam_group_detail.md")


  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "group_arn" {
    title = "Select a group:"
    sql   = query.aws_iam_group_input.sql
    width = 2
  }

  container {

    card {
      width = 2
      query = query.aws_iam_group_inline_policy_count_for_group
      args = {
        arn = self.input.group_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_iam_group_direct_attached_policy_count_for_group
      args = {
        arn = self.input.group_arn.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_iam_group_relationships_graph
      args = {
        arn = self.input.group_arn.value
      }
      category "aws_iam_group" {
        color = "Orange"
      }

      category "aws_iam_policy" {
        color = "blue"
        href  = "/aws_insights.dashboard.aws_iam_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_iam_user" {
        href = "${dashboard.aws_iam_user_detail.url_path}?input.user_arn={{.properties.ARN | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/iam_user_light.svg"))
      }

      category "uses" {
        color = "green"
      }
    }
  }

  container {

    container {

      title = "Overview"

      table {
        type  = "line"
        width = 6
        query = query.aws_iam_group_overview
        args = {
          arn = self.input.group_arn.value
        }

      }

    }

  }

  container {

    title = "AWS IAM Group Analysis"

    table {
      title = "Users"
      width = 6
      column "User Name" {
        href = "${dashboard.aws_iam_user_detail.url_path}?input.user_arn={{.'User ARN' | @uri}}"
      }

      query = query.aws_iam_users_for_group
      args = {
        arn = self.input.group_arn.value
      }

    }

    table {
      title = "Policies"
      width = 6
      query = query.aws_iam_all_policies_for_group
      args = {
        arn = self.input.group_arn.value
      }
    }

  }

}

query "aws_iam_group_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id
      ) as tags
    from
      aws_iam_group
    order by
      title;
  EOQ
}

query "aws_iam_group_inline_policy_count_for_group" {
  sql = <<-EOQ
    select
      case when inline_policies is null then 0 else jsonb_array_length(inline_policies) end as value,
      'Inline Policies' as label,
      case when (inline_policies is null) or (jsonb_array_length(inline_policies) = 0)  then 'ok' else 'alert' end as type
    from
      aws_iam_group
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_group_direct_attached_policy_count_for_group" {
  sql = <<-EOQ
    select
      case when attached_policy_arns is null then 0 else jsonb_array_length(attached_policy_arns) end as value,
      'Attached Policies' as label,
      case when (attached_policy_arns is null) or (jsonb_array_length(attached_policy_arns) = 0)  then 'alert' else 'ok' end as type
    from
      aws_iam_group
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_group_relationships_graph" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      group_id as id,
      name as title,
      'aws_iam_group' as category,
      jsonb_build_object( 'ARN', arn, 'Path', path, 'Create Date', create_date, 'Account ID', account_id ) as properties
    from
      aws_iam_group
    where
      arn = $1

    -- To IAM Policies (node)
    union all
    select
      null as from_id,
      null as to_id,
      policy_id as id,
      name as title,
      'aws_iam_policy' as category,
      jsonb_build_object( 'ARN', arn, 'AWS Managed', is_aws_managed::text, 'Attached', is_attached::text, 'Create Date', create_date, 'Account ID', account_id ) as properties
    from
      aws_iam_policy
    where
      arn in
      (
        select
          jsonb_array_elements_text(attached_policy_arns)
        from
          aws_iam_group
        where
          arn = $1
      )

    -- To IAM Policies (edge)
    union all
    select
      r.group_id as from_id,
      p.policy_id as to_id,
      null as id,
      'has policy' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', p.account_id ) as properties
    from
      aws_iam_group as r,
      jsonb_array_elements_text(attached_policy_arns) as arns
      left join
        aws_iam_policy as p
        on p.arn = arns
    where
      r.arn = $1

    -- From IAM Users (node)
    union all
    select
      null as from_id,
      null as to_id,
      u.name as id,
      u.name as title,
      'aws_iam_user' as category,
      jsonb_build_object( 'ARN', u.arn, 'path', path, 'Create Date', create_date, 'MFA Enabled', mfa_enabled::text, 'Account ID', u.account_id ) as properties
    from
      aws_iam_user as u,
      jsonb_array_elements(groups) as g
    where
      g ->> 'Arn' = $1

    -- From IAM Users (edge)
    union all
    select
      u.name as from_id,
      g ->> 'GroupId' as from_id,
      null as id,
      'in group' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', u.account_id ) as properties
    from
      aws_iam_user as u,
      jsonb_array_elements(groups) as g
    where
      g ->> 'Arn' = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}

query "aws_iam_group_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      create_date as "Create Date",
      group_id as "Group ID",
      arn as "ARN",
      account_id as "Account ID"
    from
      aws_iam_group
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_users_for_group" {
  sql = <<-EOQ
    select
      u ->> 'UserName' as "User Name",
      u ->> 'Arn' as "User ARN",
      u ->> 'UserId' as "User ID"
    from
      aws_iam_group as g,
      jsonb_array_elements(users) as u
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_all_policies_for_group" {
  sql = <<-EOQ
    -- Policies (attached to groups)
    select
      split_part(policy_arn, '/','2') as "Policy",
      policy_arn as "ARN",
      'Attached to Group' as "Via"
    from
      aws_iam_group as g,
      jsonb_array_elements_text(g.attached_policy_arns) as policy_arn
    where
      g.arn = $1

    -- Policies (inline from groups)
    union select
      i ->> 'PolicyName' as "Policy",
      'N/A' as "ARN",
      'Inline' as "Via"
    from
      aws_iam_group as grp,
      jsonb_array_elements(grp.inline_policies_std) as i
    where
      arn = $1
  EOQ

  param "arn" {}
}

