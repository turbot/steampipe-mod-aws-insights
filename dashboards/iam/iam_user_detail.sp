dashboard "iam_user_detail" {

  title         = "AWS IAM User Detail"
  documentation = file("./dashboards/iam/docs/iam_user_detail.md")

  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "user_arn" {
    title = "Select a user:"
    sql   = query.iam_user_input.sql
    width = 4
  }

  container {

    card {
      width = 3
      query = query.iam_user_mfa_for_user
      args  = [self.input.user_arn.value]
    }

    card {
      width = 3
      query = query.iam_boundary_policy_for_user
      args  = [self.input.user_arn.value]
    }

    card {
      width = 3
      query = query.iam_user_inline_policy_count_for_user
      args  = [self.input.user_arn.value]
    }

    card {
      width = 3
      query = query.iam_user_direct_attached_policy_count_for_user
      args  = [self.input.user_arn.value]
    }

  }

  with "iam_groups_for_iam_user" {
    query = query.iam_groups_for_iam_user
    args  = [self.input.user_arn.value]
  }

  with "iam_policies_for_iam_user" {
    query = query.iam_policies_for_iam_user
    args  = [self.input.user_arn.value]
  }


  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.iam_group
        args = {
          iam_group_arns = with.iam_groups_for_iam_user.rows[*].group_arn
        }
      }

      node {
        base = node.iam_policy
        args = {
          iam_policy_arns = with.iam_policies_for_iam_user.rows[*].policy_arn
        }
      }

      node {
        base = node.iam_user
        args = {
          iam_user_arns = [self.input.user_arn.value]
        }
      }

      node {
        base = node.iam_user_access_key
        args = {
          iam_user_arns = [self.input.user_arn.value]
        }
      }

      node {
        base = node.iam_user_inline_policy
        args = {
          iam_user_arns = [self.input.user_arn.value]
        }
      }

      edge {
        base = edge.iam_group_to_iam_user
        args = {
          iam_group_arns = with.iam_groups_for_iam_user.rows[*].group_arn
        }
      }

      edge {
        base = edge.iam_user_to_iam_access_key
        args = {
          iam_user_arns = [self.input.user_arn.value]
        }
      }

      edge {
        base = edge.iam_user_to_iam_policy
        args = {
          iam_user_arns = [self.input.user_arn.value]
        }
      }

      edge {
        base = edge.iam_user_to_inline_policy
        args = {
          iam_user_arns = [self.input.user_arn.value]
        }
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
        query = query.iam_user_overview
        args  = [self.input.user_arn.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.iam_user_tags
        args  = [self.input.user_arn.value]
      }

    }

    container {

      width = 6

      table {
        title = "Console Password"
        query = query.iam_user_console_password
        args  = [self.input.user_arn.value]
      }

      table {
        title = "Access Keys"
        query = query.iam_user_access_keys
        args  = [self.input.user_arn.value]
      }

      table {
        title = "MFA Devices"
        query = query.iam_user_mfa_devices
        args  = [self.input.user_arn.value]
      }

    }

  }

  container {

    title = "AWS IAM User Policy Analysis"

    flow {
      type  = "sankey"
      title = "Attached Policies"
      query = query.iam_user_manage_policies_sankey
      args  = [self.input.user_arn.value]

      category "iam_group" {
        color = "ok"
      }
    }

    table {
      title = "Groups"
      width = 6
      query = query.iam_groups_for_user
      args  = [self.input.user_arn.value]

      column "Name" {
        // cyclic dependency prevents use of url_path, hardcode for now
        //href = "${dashboard.iam_group_detail.url_path}?input.group_arn={{.'ARN' | @uri}}"
        href = "/aws_insights.dashboard.iam_group_detail?input.group_arn={{.ARN | @uri}}"

      }
    }

    table {
      title = "Policies"
      width = 6
      query = query.iam_all_policies_for_user
      args  = [self.input.user_arn.value]
    }

  }

}

# Input queries

query "iam_user_input" {
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

# With queries

query "iam_groups_for_iam_user" {
  sql = <<-EOQ
    select
      g ->> 'Arn' as group_arn
    from
      aws_iam_user,
      jsonb_array_elements(groups) as g
    where
      arn = $1
  EOQ
}

query "iam_policies_for_iam_user" {
  sql = <<-EOQ
    select
      jsonb_array_elements_text(attached_policy_arns) as policy_arn
    from
      aws_iam_user
    where
      arn = $1
  EOQ
}

# Card queries

query "iam_user_mfa_for_user" {
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
}

query "iam_boundary_policy_for_user" {
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

}

query "iam_user_inline_policy_count_for_user" {
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
}

query "iam_user_direct_attached_policy_count_for_user" {
  sql = <<-EOQ
    select
      coalesce(jsonb_array_length(attached_policy_arns), 0) as value,
      'Attached Policies' as label,
      case when coalesce(jsonb_array_length(attached_policy_arns), 0) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_user
    where
     arn = $1
  EOQ
}

# Other detail page queries

query "iam_user_overview" {
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
}

query "iam_user_tags" {
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
}

query "iam_user_console_password" {
  sql = <<-EOQ
    select
      password_last_used as "Password Last Used",
      mfa_enabled as "MFA Enabled"
    from
      aws_iam_user
    where
      arn = $1
  EOQ
}

query "iam_user_access_keys" {
  sql = <<-EOQ
    select
      access_key_id as "Access Key ID",
      a.status as "Status",
      a.create_date as "Create Date"
    from
      aws_iam_access_key as a left join aws_iam_user as u on u.name = a.user_name and u.account_id = a.account_id
    where
      u.arn = $1
  EOQ
}

query "iam_user_mfa_devices" {
  sql = <<-EOQ
    select
      mfa ->> 'SerialNumber' as "Serial Number",
      mfa ->> 'EnableDate' as "Enable Date",
      path as "User Path"
    from
      aws_iam_user as u,
      jsonb_array_elements(mfa_devices) as mfa
    where
      arn = $1
  EOQ
}

query "iam_user_manage_policies_sankey" {
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
}

query "iam_groups_for_user" {
  sql = <<-EOQ
    select
      g ->> 'GroupName' as "Name",
      g ->> 'Arn' as "ARN"
    from
      aws_iam_user as u,
      jsonb_array_elements(groups) as g
    where
      u.arn = $1
  EOQ
}

query "iam_all_policies_for_user" {
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
}


