// this is just for testing while `with` is in development... 
locals {
  test_group_arn = "arn:aws:iam::533793682495:group/turbot/admin"
}


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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "attached_policies" {
        sql = <<-EOQ
          select
            jsonb_array_elements_text(attached_policy_arns) as policy_arn
          from
            aws_iam_group
          where
            arn = $1
        EOQ

        #args = [self.input.group_arn.value]
        args = [local.test_group_arn]
      }

      with "members" {
        sql = <<-EOQ
          select
            member ->> 'Arn' as user_arn
          from
            aws_iam_group,
            jsonb_array_elements(users) as member
          where
            arn = $1

        EOQ

        #args = [self.input.group_arn.value]
        args = [local.test_group_arn]
      }

      nodes = [
        node.aws_iam_group_nodes,
        node.aws_iam_policy_nodes,
        node.aws_iam_user_nodes,

        // Add inline policies...
        // node.aws_iam_inline_policy_nodes
      ]

      edges = [
        edge.aws_iam_policy_from_iam_group_edges,
        edge.aws_iam_group_to_iam_user_edges,

      ]

      args = {
        group_arns = [local.test_group_arn] //[self.input.group_arn.value]
        policy_arns = with.attached_policies.rows[*].policy_arn
        user_arns = with.members.rows[*].user_arn
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


node "aws_iam_group_nodes" {
  category = category.aws_iam_group

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

  param "group_arns" {}
}



edge "aws_iam_group_to_iam_user_edges" {
  title = "has member"

  sql = <<-EOQ
   select
      user_arns as to_id,
      group_arns as from_id
    from
      unnest($1::text[]) as user_arns,
      unnest($2::text[]) as group_arns
  EOQ

  param "user_arns" {}
  param "group_arns" {}

}