dashboard "iam_policy_detail" {
  title         = "AWS IAM Policy Detail"
  documentation = file("./dashboards/iam/docs/iam_policy_detail.md")
  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "policy_arn" {
    title = "Select a policy:"
    query = query.iam_policy_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.iam_policy_aws_managed
      args = {
        policy_arn = self.input.policy_arn.value
      }
    }

    card {
      width = 2
      query = query.iam_policy_attached
      args = {
        policy_arn = self.input.policy_arn.value
      }
    }
  }

  # container {

  #   graph {
  #     title = "Relationships"
  #     type  = "graph"

  #     with "iam_groups" {
  #       sql = <<-EOQ
  #         select
  #           arn as group_arn
  #         from
  #           aws_iam_group,
  #           jsonb_array_elements_text(attached_policy_arns) as policy_arn
  #         where
  #           policy_arn = $1;
  #       EOQ

  #       args = [self.input.policy_arn.value]
  #     }

  #     with "iam_policy_std" {
  #       sql = <<-EOQ
  #         select
  #           policy_std
  #         from
  #           aws_iam_policy
  #         where
  #           arn = $1
  #         limit 1;  -- aws managed policies will appear once for each connection in the aggregator, but we only need one...
  #       EOQ

  #       args = [self.input.policy_arn.value]
  #     }

  #     with "iam_roles" {
  #       sql = <<-EOQ
  #         select
  #           arn as role_arn
  #         from
  #           aws_iam_role,
  #           jsonb_array_elements_text(attached_policy_arns) as policy_arn
  #         where
  #           policy_arn = $1;
  #       EOQ

  #       args = [self.input.policy_arn.value]
  #     }

  #     with "iam_users" {
  #       sql = <<-EOQ
  #         select
  #           arn as user_arn
  #         from
  #           aws_iam_user,
  #           jsonb_array_elements_text(attached_policy_arns) as policy_arn
  #         where
  #           policy_arn = $1;
  #       EOQ

  #       args = [self.input.policy_arn.value]
  #     }

  #     nodes = [
  #       node.iam_group,
  #       node.iam_policy,
  #       node.iam_policy_statement,
  #       node.iam_policy_statement_action_notaction,
  #       node.iam_policy_statement_condition,
  #       node.iam_policy_statement_condition_key,
  #       node.iam_policy_statement_condition_key_value,
  #       node.iam_policy_statement_resource_notresource,
  #       node.iam_role,
  #       node.iam_user
  #     ]

  #     edges = [

  #       edge.iam_group_to_iam_policy,
  #       edge.iam_policy_statement,
  #       edge.iam_policy_statement_action,
  #       edge.iam_policy_statement_condition,
  #       edge.iam_policy_statement_condition_key,
  #       edge.iam_policy_statement_condition_key_value,
  #       edge.iam_policy_statement_notaction,
  #       edge.iam_policy_statement_notresource,
  #       edge.iam_policy_statement_resource,
  #       edge.iam_role_to_iam_policy,
  #       edge.iam_user_to_iam_policy
  #     ]

  #     args = {
  #       iam_group_arns  = with.iam_groups.rows[*].group_arn
  #       iam_policy_arns = [self.input.policy_arn.value]
  #       iam_policy_stds = with.iam_policy_std.rows[0].policy_std
  #       iam_role_arns   = with.iam_roles.rows[*].role_arn
  #       iam_user_arns   = with.iam_users.rows[*].user_arn
  #     }
  #   }

  # }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.iam_policy_overview
        args = {
          policy_arn = self.input.policy_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.iam_policy_tags
        args = {
          policy_arn = self.input.policy_arn.value
        }

      }

    }

    container {
      width = 6
      table {
        title = "Policy Statement"
        query = query.iam_policy_statement
        args = {
          policy_arn = self.input.policy_arn.value
        }

        column "Action" {
          href = "/aws_insights.dashboard.iam_action_glob_report?input.action_glob={{.\"Action\" | @uri}}"
        }
        column "NotAction" {
          href = "/aws_insights.dashboard.iam_action_glob_report?input.action_glob={{.\"NotAction\" | @uri}}"
        }
      }

    }

  }
}

query "iam_policy_input" {
  sql = <<-EOQ
    with policies as (
      select
        title as label,
        arn as value,
        json_build_object(
          'account_id', account_id
        ) as tags
      from
        aws_iam_policy
      where
        not is_aws_managed
      union all select
        distinct on (arn)
        title as label,
        arn as value,
        json_build_object(
          'account_id', 'AWS Managed'
        ) as tags
      from
        aws_iam_policy
      where
        is_aws_managed
    )
    select
      *
    from
      policies
    order by
      label;
  EOQ
}

query "iam_policy_aws_managed" {
  sql = <<-EOQ
    select
      case when is_aws_managed then 'AWS' else 'Customer' end as value,
      'Managed By' as label
    from
      aws_iam_policy
    where
      arn = $1
  EOQ

  param "policy_arn" {}
}

query "iam_policy_attached" {
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

  param "policy_arn" {}
}


query "iam_policy_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      path as "Path",
      create_date as "Create Date",
      update_date as "Update Date",
      policy_id as "Policy ID",
      arn as "ARN",
      case is_aws_managed
        when true then 'AWS Managed'
        else account_id
      end as "Account ID"
    from
      aws_iam_policy
    where
      arn = $1
    limit 1
  EOQ

  param "policy_arn" {}
}

query "iam_policy_tags" {
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

  param "policy_arn" {}
}

query "iam_policy_statement" {
  sql = <<-EOQ
    with policy as (
      select
        distinct on (arn)
        *
      from
        aws_iam_policy
      where
        arn =  $1
    )
    select
      coalesce(t.stmt ->> 'Sid', concat('[', i::text, ']')) as "Statement",
      t.stmt ->> 'Effect' as "Effect",
      action as "Action",
      notaction as "NotAction",
      resource as "Resource",
      notresource as "NotResource",
      t.stmt ->> 'Condition' as "Condition"
    from
      policy as p, --aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') with ordinality as t(stmt,i)
      left join jsonb_array_elements_text(t.stmt -> 'Action') as action on true
      left join jsonb_array_elements_text(t.stmt -> 'NotAction') as notaction on true
      left join jsonb_array_elements_text(t.stmt -> 'Resource') as resource on true
      left join jsonb_array_elements_text(t.stmt -> 'NotResource') as notresource on true
  EOQ

  param "policy_arn" {}
}



