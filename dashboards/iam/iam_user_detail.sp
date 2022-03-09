dashboard "aws_iam_user_detail" {

  title = "AWS IAM User Detail"

  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "user_arn" {
    title = "Select a user:"
    sql   = query.aws_iam_user_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_iam_user_mfa_for_user
      args  = {
        arn = self.input.user_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_iam_boundary_policy_for_user
      args  = {
        arn = self.input.user_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_iam_user_inline_policy_count_for_user
      args  = {
        arn = self.input.user_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_iam_user_direct_attached_policy_count_for_user
      args  = {
        arn = self.input.user_arn.value
      }
    }

  }

  container {

    container {

      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_iam_user_overview
        args  = {
          arn = self.input.user_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_iam_user_tags
        args  = {
          arn = self.input.user_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Console Password"
        query = query.aws_iam_user_console_password
        args  = {
          arn = self.input.user_arn.value
        }
      }

      table {
        title = "Access Keys"
        query = query.aws_iam_user_access_keys
        args  = {
          arn = self.input.user_arn.value
        }
      }

      table {
        title = "MFA Devices"
        query = query.aws_iam_user_mfa_devices
        args  = {
          arn = self.input.user_arn.value
        }
      }

    }

  }

  container {

    title = "AWS IAM User Policy Analysis"

    flow {
      type  = "sankey"
      title = "Attached Policies"
      query = query.aws_iam_user_manage_policies_sankey
      args  = {
        arn = self.input.user_arn.value
      }

      category "aws_iam_group" {
        color = "green"
      }
    }

    table {
      title = "Groups"
      width = 6
      query = query.aws_iam_groups_for_user
      args  = {
        arn = self.input.user_arn.value
      }

      column "Name" {
        // cyclic dependency.. harcode for now
        //href = "${dashboard.aws_iam_group_detail.url_path}?input.group_arn={{.'ARN' | @uri}}"
        href = "http://localhost:9194/aws_insights.dashboard.aws_iam_group_detail?input.group_arn={{.'ARN'}}"

      }
    }

    table {
      title = "Policies"
      width = 6
      query = query.aws_iam_all_policies_for_user
      args  = {
        arn = self.input.user_arn.value
      }
    }

  }

}

query "aws_iam_user_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id
      ) as tags
    from
      aws_iam_user
    order by
      title;
  EOQ
}

query "aws_iam_user_mfa_for_user" {
  sql = <<-EOQ
    select
      case when mfa_enabled then 'Enabled' else 'Disabled' end as value,
      'MFA Status' as label,
      case when mfa_enabled then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_boundary_policy_for_user" {
  sql = <<-EOQ
    select
      case
        when permissions_boundary_type is null then 'Not set'
        when permissions_boundary_type = '' then 'Not set'
        else substring(permissions_boundary_arn, 'arn:aws:iam::\d{12}:.+\/(.*)')
      end as value,
      'Boundary Policy' as label,
      case
        when permissions_boundary_type is null then 'alert'
        when permissions_boundary_type = '' then 'alert'
        else 'ok'
      end as type
    from
      aws_iam_user
    where
      arn = $1
  EOQ

  param "arn" {}

}

query "aws_iam_user_inline_policy_count_for_user" {
  sql = <<-EOQ
    select
      coalesce(jsonb_array_length(inline_policies),0) as value,
      'Inline Policies' as label,
      case when coalesce(jsonb_array_length(inline_policies),0) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_user_direct_attached_policy_count_for_user" {
  sql = <<-EOQ
    select
      coalesce(jsonb_array_length(attached_policy_arns), 0) as value,
      'Directly Attached Policies' as label,
      case when coalesce(jsonb_array_length(attached_policy_arns), 0) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
     arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_user_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      create_date as "Create Date",
      permissions_boundary_arn as "Boundary Policy",
      user_id as "User ID",
      arn as "ARN",
      account_id as "Account ID"
    from
      aws_iam_user
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_user_tags" {
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

query "aws_iam_user_console_password" {
  sql = <<-EOQ
    select
      password_last_used as "Password Last Used",
      mfa_enabled as "MFA Enabled"
    from
      aws_iam_user
    where
      arn  = $1
  EOQ

  param "arn" {}
}

query "aws_iam_user_access_keys" {
  sql = <<-EOQ
    select
      access_key_id  as "Access Key ID",
      a.status as "Status",
      a.create_date as "Create Date"
    from
      aws_iam_access_key as a left join aws_iam_user as u on u.name = a.user_name
    where
      u.arn  = $1
  EOQ

  param "arn" {}
}

query "aws_iam_user_mfa_devices" {
  sql = <<-EOQ
    select
      mfa ->> 'SerialNumber' as "Serial Number",
      mfa ->> 'EnableDate' as "Enable Date",
      path as "User Path"
    from
      aws_iam_user as u,
      jsonb_array_elements(mfa_devices) as mfa
    where
      arn  = $1
  EOQ

  param "arn" {}
}

query "aws_iam_user_manage_policies_sankey" {
  sql = <<-EOQ

    with args as (
        select $1 as iam_user_arn
    )

    -- User
    select
      null as from_id,
      arn as id,
      title,
      0 as depth,
      'aws_iam_user' as category
    from
      aws_iam_user
    where
      arn in (select iam_user_arn from args)

    -- Groups
    union select
      u.arn as from_id,
      g ->> 'Arn' as id,
      g ->> 'GroupName' as title,
      1 as depth,
      'aws_iam_group' as category
    from
      aws_iam_user as u,
      jsonb_array_elements(groups) as g
    where
      u.arn in (select iam_user_arn from args)

    -- Policies (attached to groups)
    union select
      g.arn as from_id,
      p.arn as id,
      p.title as title,
      2 as depth,
      'aws_iam_policy' as category
    from
      aws_iam_user as u,
      aws_iam_policy as p,
      jsonb_array_elements(u.groups) as user_groups
      inner join aws_iam_group g on g.arn = user_groups ->> 'Arn'
    where
      g.attached_policy_arns :: jsonb ? p.arn
      and u.arn in (select iam_user_arn from args)

    -- Policies (inline from groups)
    union select
      grp.arn as from_id,
      concat(grp.group_id, '_' , i ->> 'PolicyName') as id,
      concat(i ->> 'PolicyName', ' (inline)') as title,
      2 as depth,
      'inline_policy' as category
    from
      aws_iam_user as u,
      jsonb_array_elements(u.groups) as g,
      aws_iam_group as grp,
      jsonb_array_elements(grp.inline_policies_std) as i
    where
      grp.arn = g ->> 'Arn'
      and u.arn in (select iam_user_arn from args)

    -- Policies (attached to user)
    union select
      u.arn as from_id,
      p.arn as id,
      p.title as title,
      2 as depth,
      'aws_iam_policy' as category
    from
      aws_iam_user as u,
      jsonb_array_elements_text(u.attached_policy_arns) as pol_arn,
      aws_iam_policy as p
    where
      u.attached_policy_arns :: jsonb ? p.arn
      and pol_arn = p.arn
      and u.arn in (select iam_user_arn from args)

    -- Inline Policies (defined on user)
    union select
      u.arn as from_id,
      concat('inline_', i ->> 'PolicyName') as id,
      concat(i ->> 'PolicyName', ' (inline)') as title,
      2 as depth,
      'inline_policy' as category
    from
      aws_iam_user as u,
      jsonb_array_elements(inline_policies_std) as i
    where
      u.arn in (select iam_user_arn from args)
  EOQ

  param "arn" {}
}




query "aws_iam_groups_for_user" {
  sql   = <<-EOQ
    select
      g ->> 'GroupName' as "Name",
      g ->> 'Arn' as "ARN"
    from
      aws_iam_user as u,
      jsonb_array_elements(groups) as g
    where
      u.arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_all_policies_for_user" {
  sql = <<-EOQ

    -- Policies (attached to groups)
    select
      p.title as "Policy",
      p.arn as "ARN",
      'Group: ' || g.title as "Via"
    from
      aws_iam_user as u,
      aws_iam_policy as p,
      jsonb_array_elements(u.groups) as user_groups
      inner join aws_iam_group g on g.arn = user_groups ->> 'Arn'
    where
      g.attached_policy_arns :: jsonb ? p.arn
      and u.arn = $1

    -- Policies (inline from groups)
    union select
      i ->> 'PolicyName' as "Policy",
      'N/A' as "ARN",
      'Group: ' || grp.title || ' (inline)' as "Via"
    from
      aws_iam_user as u,
      jsonb_array_elements(u.groups) as g,
      aws_iam_group as grp,
      jsonb_array_elements(grp.inline_policies_std) as i
    where
      grp.arn = g ->> 'Arn'
      and u.arn = $1

    -- Policies (attached to user)
    union select
      p.title as "Policy",
      p.arn as "ARN",
      'Attached to User' as "Via"
    from
      aws_iam_user as u,
      jsonb_array_elements_text(u.attached_policy_arns) as pol_arn,
      aws_iam_policy as p
    where
      u.attached_policy_arns :: jsonb ? p.arn
      and pol_arn = p.arn
      and u.arn = $1

    -- Inline Policies (defined on user)
    union select
      i ->> 'PolicyName' as "Policy",
      'N/A' as "ARN",
      'Inline' as "Via"
    from
      aws_iam_user as u,
      jsonb_array_elements(inline_policies_std) as i
    where
      u.arn = $1
  EOQ

  param "arn" {}
}
