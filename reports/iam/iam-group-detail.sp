variable "iam_detail_group_arn" {
  type    = string
  default = "arn:aws:iam::013122550996:group/demo-group"
}


query "aws_iam_group_input" {
  sql = <<EOQ
    select
      title as label,
      arn as value
    from
      aws_iam_group
    order by
      title;
EOQ
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
      arn = 'arn:aws:iam::013122550996:group/demo-group'
  EOQ
}

query "aws_iam_group_inline_policy_count_for_group" {
  sql = <<-EOQ
    select
      jsonb_array_length(inline_policies) as value,
      'Inline Policies' as label,
      case when jsonb_array_length(inline_policies) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_group
    where
      arn = 'arn:aws:iam::013122550996:group/demo-group'
  EOQ
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
      g.arn = 'arn:aws:iam::013122550996:group/demo-group'
  EOQ
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
      grp.arn = 'arn:aws:iam::013122550996:group/demo-group'
  EOQ
}

dashboard "aws_iam_group_detail" {
  title = "AWS IAM Group Detail"

  input "user_arn" {
    title = "User"
    sql   = query.aws_iam_user_input.sql
    width = 2
  }

  container {

    # Assessments
    card {
      sql   = query.aws_iam_group_inline_policy_count_for_group.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_group_direct_attached_policy_count_for_group.sql
      width = 2
    }
  }

  container {

    container {
      title = "Overview"

      table {
        width = 8
        sql   = <<-EOQ
          select
            name as "Name",
            create_date as "Create Date",
            group_id as "Group ID",
            arn as "ARN",
            account_id as "Account ID"
          from
            aws_iam_group
          where
           arn = 'arn:aws:iam::013122550996:group/demo-group'
        EOQ
      }
    }
  }

  container {
    title = "AWS IAM Group Analysis"
    
    table {
      title = "Users"
      width = 6
      sql   = query.aws_iam_users_for_group.sql

    }

    table {
      title = "Policies"
      width = 6
      sql   = query.aws_iam_all_policies_for_group.sql
    }
  }

}
