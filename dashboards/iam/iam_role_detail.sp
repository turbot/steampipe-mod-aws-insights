dashboard "aws_iam_role_detail" {

  title = "AWS IAM Role Detail"

  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "role_arn" {
    title = "Select a role:"
    sql   = query.aws_iam_role_input.sql
    width = 2
  }

  container {

    card {
      query   = query.aws_iam_boundary_policy_for_role
      width = 2
      args  = {
        arn = self.input.role_arn.value
      }
    }

    card {
      query   = query.aws_iam_role_inline_policy_count_for_role
      width = 2
      args  = {
        arn = self.input.role_arn.value
      }
    }

    card {
      query   = query.aws_iam_role_direct_attached_policy_count_for_role
      width = 2
      args  = {
        arn = self.input.role_arn.value
      }
    }

  }

  container {

    title = "Overview"

    table {
      query   = query.aws_iam_role_detail_overview
      width = 6
      args  = {
        arn = self.input.role_arn.value
      }
    }

    table {
      title = "Tags"
      width = 6
      sql   = <<-EOQ
        select
          tag ->> 'Key' as "Key",
          tag ->> 'Value' as "Value"
        from
          aws_iam_role,
          jsonb_array_elements(tags_src) as tag
        where
          arn = $1
      EOQ

      param "arn" {}
      args  = {
        arn = self.input.role_arn.value
      }
    }

  }

  container {

    title = "AWS IAM Role Policy Analysis"


    # hierarchy {
    #   type  = "sankey"
    #   title = "Attached Policies"
    #   sql   = query.aws_iam_user_manage_policies_sankey.sql

    #   category "aws_iam_group" {
    #     color = "green"
    #   }
    # }


    table {
      title = "Groups"
      width = 6
      query   = query.aws_iam_groups_for_user
      args  = {
        arn = self.input.role_arn.value
      }
    }

    table {
      title = "Policies"
      width = 6
      query   = query.aws_iam_all_policies_for_role
      args  = {
        arn = self.input.role_arn.value
      }
    }

  }

}

query "aws_iam_role_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id
      ) as tags
    from
      aws_iam_role
    order by
      title;
  EOQ
}

query "aws_iam_boundary_policy_for_role" {
  sql = <<-EOQ
    select
      case
        when permissions_boundary_type is null then 'Not Set'
        when permissions_boundary_type = '' then 'Not Set'
        else substring(permissions_boundary_arn, 'arn:aws:iam::\d{12}:.+\/(.*)')
      end as value,
      'Boundary Policy' as label,
      case
        when permissions_boundary_type is null then 'alert'
        when permissions_boundary_type = '' then 'alert'
        else 'ok'
      end as type
    from
      aws_iam_role
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_role_inline_policy_count_for_role" {
  sql = <<-EOQ
    select
      jsonb_array_length(inline_policies) as value,
      'Inline Policies' as label,
      case when jsonb_array_length(inline_policies) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_role
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_role_direct_attached_policy_count_for_role" {
  sql = <<-EOQ
    select
      jsonb_array_length(attached_policy_arns) as value,
      'Direct Attached Policies' as label,
      case when jsonb_array_length(attached_policy_arns) > 0 then 'ok' else 'alert' end as type
    from
      aws_iam_role
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_role_detail_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      create_date as "Create Date",
      permissions_boundary_arn as "Boundary Policy",
      role_id as "Role ID",
      arn as "ARN",
      account_id as "Account ID"
    from
      aws_iam_role
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_all_policies_for_role" {
  sql = <<-EOQ
    -- Policies (attached to groups)
    select
      split_part(policy_arn, '/','2') as "Policy",
      policy_arn as "ARN",
      'Attached to Role' as "Via"
    from
      aws_iam_role as r,
      jsonb_array_elements_text(r.attached_policy_arns) as policy_arn
    where
      r.arn = 'arn:aws:iam::013122550996:role/turbot/admin'
    -- Inline Policies (defined on role)
    union select
      i ->> 'PolicyName' as "Policy",
      'N/A' as "ARN",
      'Inline' as "Via"
    from
      aws_iam_role as r,
      jsonb_array_elements(inline_policies_std) as i
    where
      arn = $1
  EOQ

  param "arn" {}
}
