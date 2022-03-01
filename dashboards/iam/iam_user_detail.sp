query "aws_iam_user_input" {
  sql = <<EOQ
    select
      arn as label,
      arn as value
    from
      aws_iam_user
    order by
      arn;
EOQ
}

query "aws_iam_user_name_for_user" {
  sql = <<-EOQ
    select
      name as "Username"
    from
      aws_iam_user
    where
      arn = $1
  EOQ

  param "arn" {}
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

query "aws_iam_user_direct_attached_policy_count_for_user" {
  sql = <<-EOQ
    select
      coalesce(jsonb_array_length(attached_policy_arns), 0) as value,
      'Direct Attached Policies' as label,
      case when coalesce(jsonb_array_length(attached_policy_arns), 0) = 0 then 'ok' else 'alert' end as type
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

query "aws_iam_boundary_policy_for_user" {
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
      aws_iam_user 
    where
      arn = $1
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

query "aws_iam_user_manage_policies_sankey" {
  sql = <<EOQ

    with args as (
        select $1 as iam_user_arn
    )

    -- User
    select
      null as parent,
      arn as id,
      title as name,
      0 as depth,
      'aws_iam_user' as category
    from
      aws_iam_user
    where
      arn in (select iam_user_arn from args)

    -- Groups
    union select
      u.arn as parent,
      g ->> 'Arn' as id,
      g ->> 'GroupName' as name,
      1 as depth,
      'aws_iam_group' as category
    from
      aws_iam_user as u,
      jsonb_array_elements(groups) as g
    where
      u.arn in (select iam_user_arn from args)

    -- Policies (attached to groups)
    union select
      g.arn as parent,
      p.arn as id,
      p.title as name,
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
      grp.arn as parent,
      concat(grp.group_id, '_' , i ->> 'PolicyName') as id,
      concat(i ->> 'PolicyName', ' (inline)') as name,
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
      u.arn as parent,
      p.arn as id,
      p.title as name,
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
      u.arn as parent,
      concat('inline_', i ->> 'PolicyName') as id,
      concat(i ->> 'PolicyName', ' (inline)') as name,
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

    # Assessments
    card {
      width = 2

      query = query.aws_iam_user_name_for_user
      args  = {
        arn = self.input.user_arn.value
      }
    }

    # Assessments
    card {
      width = 2

      query = query.aws_iam_user_mfa_for_user
      args  = {
        arn = self.input.user_arn.value
      }
    }

    card {
      query = query.aws_iam_boundary_policy_for_user
      width = 2

      args = {
        arn = self.input.user_arn.value
      }
    }

    card {
      query = query.aws_iam_user_inline_policy_count_for_user
      width = 2

      args = {
        arn = self.input.user_arn.value
      }
    }

    card {
      query = query.aws_iam_user_direct_attached_policy_count_for_user
      width = 2

      args = {
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

        args = {
          arn = self.input.user_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          select
            tag ->> 'Key' as "Key",
            tag ->> 'Value' as "Value"
          from
            aws_iam_user,
            jsonb_array_elements(tags_src) as tag
          where
            arn = $1
        EOQ

        param "arn" {}

        args = {
          arn = self.input.user_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Console Password"
        sql   = <<-EOQ
          select
            name as "Name",
           -- create_date as "Create Date",
            password_last_used as "Password Last Used",
            mfa_enabled as "MFA Enabled"
          from
            aws_iam_user
          where
           arn  = $1
        EOQ

        param "arn" {}

        args = {
          arn = self.input.user_arn.value
        }
      }

      table {
        title = "Access Keys"
        sql   = <<-EOQ
          select
            k.access_key_id as "Access Key ID",
            k.status as "Status",
            k.create_date as "Create Date"   
          from
            aws_iam_user as u,
            aws_iam_access_key as k
          where
            u.name = k.user_name
            and u.account_id = k.account_id
            and arn = $1
        EOQ

        param "arn" {}

        args = {
          arn = self.input.user_arn.value
        }
      }

      table {
        title = "MFA Devices"
        sql   = <<-EOQ
          select
            mfa ->> 'SerialNumber' as "Serial Number",
            mfa ->> 'EnableDate' as "Enable Date",
            mfa ->> 'UserName' as "Username"
          from
            aws_iam_user as u,
            jsonb_array_elements(mfa_devices) as mfa
          where
             arn = $1
        EOQ

        param "arn" {}

        args = {
          arn = self.input.user_arn.value
        }
      }

    }

  }

  container {
    title = "AWS IAM User Policy Analysis"

    hierarchy {
      type  = "sankey"
      title = "Attached Policies"
      query   = query.aws_iam_user_manage_policies_sankey
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
      query   = query.aws_iam_groups_for_user
      args  = {
        arn = self.input.user_arn.value
      }
    }

    table {
      title = "Policies"
      width = 6
      query   = query.aws_iam_all_policies_for_user
      args  = {
        arn = self.input.user_arn.value
      }
    }
  }
}