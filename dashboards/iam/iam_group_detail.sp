dashboard "aws_iam_group_detail" {

  title = "AWS IAM Group Detail"

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
      query = query.aws_iam_group_inline_policy_count_for_group
      width = 2
      args = {
        arn = self.input.group_arn.value
      }
    }

    card {
      query = query.aws_iam_group_direct_attached_policy_count_for_group
      width = 2
      args = {
        arn = self.input.group_arn.value
      }
    }

  }

  container {

    container {

      title = "Overview"

      table {
        type = "line"
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
      jsonb_array_length(attached_policy_arns) as value,
      'Direct Attached Policies' as label,
      case when jsonb_array_length(attached_policy_arns) > 0 then 'ok' else 'alert' end as type
    from
      aws_iam_group
    where
      arn = $1
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
      u ->> 'UserName' as "Name",
      u ->> 'Arn' as "ARN",
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
      g.arn = 'arn:aws:iam::013122550996:group/demo-group'

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
