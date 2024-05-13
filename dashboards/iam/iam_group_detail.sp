dashboard "iam_group_detail" {

  title         = "AWS IAM Group Detail"
  documentation = file("./dashboards/iam/docs/iam_group_detail.md")


  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "group_arn" {
    title = "Select a group:"
    query = query.iam_group_input
    width = 4
  }

  container {

    card {
      width = 3
      query = query.iam_group_inline_policy_count_for_group
      args  = [self.input.group_arn.value]
    }

    card {
      width = 3
      query = query.iam_group_direct_attached_policy_count_for_group
      args  = [self.input.group_arn.value]
    }

  }

  with "iam_policies_for_iam_group" {
    query = query.iam_policies_for_iam_group
    args  = [self.input.group_arn.value]
  }

  with "iam_users_for_iam_group" {
    query = query.iam_users_for_iam_group
    args  = [self.input.group_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.iam_group
        args = {
          iam_group_arns = [self.input.group_arn.value]
        }
      }

      node {
        base = node.iam_group_inline_policy
        args = {
          iam_group_arns = [self.input.group_arn.value]
        }
      }

      node {
        base = node.iam_policy
        args = {
          iam_policy_arns = with.iam_policies_for_iam_group.rows[*].policy_arn
        }
      }

      node {
        base = node.iam_user
        args = {
          iam_user_arns = with.iam_users_for_iam_group.rows[*].user_arn
        }
      }

      edge {
        base = edge.iam_group_to_iam_policy
        args = {
          iam_group_arns = [self.input.group_arn.value]
        }
      }

      edge {
        base = edge.iam_group_to_iam_user
        args = {
          iam_group_arns = [self.input.group_arn.value]
        }
      }

      edge {
        base = edge.iam_group_to_inline_policy
        args = {
          iam_group_arns = [self.input.group_arn.value]
        }
      }
    }
  }

  container {

    container {

      table {
        type  = "line"
        title = "Overview"
        width = 6
        query = query.iam_group_overview
        args  = [self.input.group_arn.value]
      }

    }

  }

  container {

    title = "AWS IAM Group Analysis"

    table {
      title = "Users"
      width = 6
      column "User Name" {
        href = "${dashboard.iam_user_detail.url_path}?input.user_arn={{.'User ARN' | @uri}}"
      }

      query = query.iam_users_for_group
      args  = [self.input.group_arn.value]

    }

    table {
      title = "Policies"
      width = 6
      query = query.iam_all_policies_for_group
      args  = [self.input.group_arn.value]
    }

  }
}

# Input queries

query "iam_group_input" {
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

# With queries

query "iam_policies_for_iam_group" {
  sql = <<-EOQ
    select
      jsonb_array_elements_text(attached_policy_arns) as policy_arn
    from
      aws_iam_group
    where
      arn = $1
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "iam_users_for_iam_group" {
  sql = <<-EOQ
    select
      member ->> 'Arn' as user_arn
    from
      aws_iam_group,
      jsonb_array_elements(users) as member
    where
      arn = $1
      and account_id = split_part($1, ':', 5);
  EOQ
}

# Card queries

query "iam_group_inline_policy_count_for_group" {
  sql = <<-EOQ
    select
      case when inline_policies is null then 0 else jsonb_array_length(inline_policies) end as value,
      'Inline Policies' as label,
      case when (inline_policies is null) or (jsonb_array_length(inline_policies) = 0)  then 'ok' else 'alert' end as type
    from
      aws_iam_group
    where
      arn = $1
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "iam_group_direct_attached_policy_count_for_group" {
  sql = <<-EOQ
    select
      case when attached_policy_arns is null then 0 else jsonb_array_length(attached_policy_arns) end as value,
      'Attached Policies' as label,
      case when (attached_policy_arns is null) or (jsonb_array_length(attached_policy_arns) = 0)  then 'alert' else 'ok' end as type
    from
      aws_iam_group
    where
      arn = $1
      and account_id = split_part($1, ':', 5);
  EOQ
}

# Other detail page queries

query "iam_group_overview" {
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
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "iam_users_for_group" {
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
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "iam_all_policies_for_group" {
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
      and g.account_id = split_part($1, ':', 5)
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
      and account_id = split_part($1, ':', 5);
  EOQ
}
