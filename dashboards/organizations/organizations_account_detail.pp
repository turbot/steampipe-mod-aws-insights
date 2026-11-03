dashboard "organizations_account_detail" {

  title         = "AWS Organizations Account Detail"
  documentation = file("./dashboards/organizations/docs/organizations_account_detail.md")

  tags = merge(local.organizations_common_tags, {
    type = "Detail"
  })

  input "account_arn" {
    title = "Select an account:"
    query = query.organizations_account_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.organizations_account_status
      args  = [self.input.account_arn.value]
    }

    card {
      width = 2
      query = query.organizations_account_management
      args  = [self.input.account_arn.value]
    }

    card {
      width = 2
      query = query.organizations_account_service_control_policy_count
      args  = [with.organizations_policy_attachments_for_organizations_account.rows[0].attachments]
    }

    card {
      width = 2
      query = query.organizations_account_resource_control_policy_count
      args  = [with.organizations_policy_attachments_for_organizations_account.rows[0].attachments]
    }

  }

  with "organizations_targets_for_organizations_account" {
    query = query.organizations_targets_for_organizations_account
    args  = [self.input.account_arn.value]
  }

  with "organizations_policy_attachments_for_organizations_account" {
    query = query.organizations_policy_attachments_for_targets
    args  = [with.organizations_targets_for_organizations_account.rows[*].target_arn]
  }

  with "organizations_policies_for_organizations_account" {
    query = query.organizations_policies_for_organizations_account
    args  = [with.organizations_policy_attachments_for_organizations_account.rows[0].attachments]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.organizations_root
        args = {
          organizations_root_arns = with.organizations_targets_for_organizations_account.rows[*].target_arn
        }
      }

      node {
        base = node.organizations_organizational_unit
        args = {
          organizations_organizational_unit_arns = with.organizations_targets_for_organizations_account.rows[*].target_arn
        }
      }

      node {
        base = node.organizations_account
        args = {
          organizations_account_arns = [self.input.account_arn.value]
        }
      }

      node {
        base = node.organizations_service_control_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_account.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_resource_control_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_account.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_declarative_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_account.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_tag_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_account.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_backup_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_account.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_aiservices_opt_out_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_account.rows[*].policy_arn
        }
      }

      edge {
        base = edge.organizations_parent_to_organizational_unit
        args = {
          organizations_organizational_unit_arns = with.organizations_targets_for_organizations_account.rows[*].target_arn
        }
      }

      edge {
        base = edge.organizations_parent_to_account
        args = {
          organizations_account_arns = [self.input.account_arn.value]
        }
      }

      edge {
        base = edge.organizations_target_to_policy
        args = {
          organizations_policy_attachments = with.organizations_policy_attachments_for_organizations_account.rows[0].attachments
          organizations_policy_arns = with.organizations_policies_for_organizations_account.rows[*].policy_arn
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
        query = query.organizations_account_overview
        args  = [self.input.account_arn.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.organizations_account_tags
        args  = [self.input.account_arn.value]
      }

    }

    container {
      width = 6

      table {
        title = "Effective Policies"
        query = query.organizations_account_effective_policies
        args  = [with.organizations_policy_attachments_for_organizations_account.rows[0].attachments]

        column "Policy ARN" {
          display = "none"
        }

        column "Policy" {
          href = "/aws_insights.dashboard.organizations_policy_detail?input.policy_arn={{.'Policy ARN' | @uri}}"
        }
      }

    }

  }

}

# Input queries

query "organizations_account_input" {
  sql = <<-EOQ
    select
      name as label,
      arn as value,
      json_build_object(
        'account_id', id,
        'status', status
      ) as tags
    from
      aws_organizations_account
    order by
      name;
  EOQ
}

# With queries

query "organizations_targets_for_organizations_account" {
  sql = <<-EOQ
    select
      target_arn
    from
      (${local.organizations_account_targets_sql}) as targets;
  EOQ
}

query "organizations_policies_for_organizations_account" {
  sql = <<-EOQ
    select
      distinct policy_arn
    from
      (${local.organizations_policy_attachments_sql}) as policies;
  EOQ
}

# Card queries

query "organizations_account_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value,
      case when status = 'ACTIVE' then 'ok' else 'alert' end as type
    from
      aws_organizations_account
    where
      arn = $1;
  EOQ
}

query "organizations_account_management" {
  sql = <<-EOQ
    select
      'Account Type' as label,
      case when id = account_id then 'Management' else 'Member' end as value
    from
      aws_organizations_account
    where
      arn = $1;
  EOQ
}

query "organizations_account_service_control_policy_count" {
  sql = <<-EOQ
    select
      'Effective SCPs' as label,
      count(distinct policy_arn) as value
    from
      (${local.organizations_policy_attachments_sql}) as policies
    where
      type = 'SERVICE_CONTROL_POLICY';
  EOQ
}

query "organizations_account_resource_control_policy_count" {
  sql = <<-EOQ
    select
      'Effective RCPs' as label,
      count(distinct policy_arn) as value
    from
      (${local.organizations_policy_attachments_sql}) as policies
    where
      type = 'RESOURCE_CONTROL_POLICY';
  EOQ
}

# Other detail page queries

query "organizations_account_overview" {
  sql = <<-EOQ
    with path as (
      select
        string_agg(ou.name, ' / ' order by nlevel(ou.path)) as ou_path
      from
        aws_organizations_account as a
        join aws_organizations_organizational_unit as parent on parent.id = a.parent_id
        join aws_organizations_organizational_unit as ou on ou.path @> parent.path
      where
        a.arn = $1
    )
    select
      a.name as "Name",
      a.id as "Account ID",
      a.email as "Email",
      a.status as "Status",
      'Root' || coalesce(' / ' || path.ou_path, '') as "Path",
      a.joined_method as "Joined Method",
      a.joined_timestamp as "Joined Timestamp",
      a.arn as "ARN"
    from
      aws_organizations_account as a,
      path
    where
      a.arn = $1;
  EOQ
}

query "organizations_account_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_organizations_account,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ
}

query "organizations_account_effective_policies" {
  sql = <<-EOQ
    select
      target_name as "Attached To",
      target_type as "Target Type",
      policy_name as "Policy",
      type as "Policy Type",
      aws_managed as "AWS Managed",
      policy_arn as "Policy ARN"
    from
      (${local.organizations_policy_attachments_sql}) as policies
    order by
      depth,
      type,
      policy_name;
  EOQ
}

locals {
  # The root, the organizational units on the path to the account ($1), and the account
  # itself, ordered from the root down.
  organizations_account_targets_sql = <<-EOQ
    select
      r.id as target_id,
      r.arn as target_arn,
      r.name as target_name,
      'Root' as target_type,
      0 as depth
    from
      aws_organizations_root as r
    where
      split_part(r.arn, '/', 2) = split_part($1, '/', 2)
    union all
    select
      ou.id,
      ou.arn,
      ou.name,
      'Organizational Unit',
      nlevel(ou.path) - 1
    from
      aws_organizations_account as a
      join aws_organizations_organizational_unit as parent on parent.id = a.parent_id
      join aws_organizations_organizational_unit as ou on ou.path @> parent.path
    where
      a.arn = $1
    union all
    select
      a.id,
      a.arn,
      a.name,
      'Account',
      99
    from
      aws_organizations_account as a
    where
      a.arn = $1
  EOQ
}
