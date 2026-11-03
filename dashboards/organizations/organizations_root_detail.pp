dashboard "organizations_root_detail" {

  title         = "AWS Organizations Root Detail"
  documentation = file("./dashboards/organizations/docs/organizations_root_detail.md")

  tags = merge(local.organizations_common_tags, {
    type = "Detail"
  })

  input "root_arn" {
    title = "Select a root:"
    query = query.organizations_root_input
    width = 4
  }

  input "aws_managed" {
    title = "AWS managed policies:"
    width = 2

    option "false" {
      label = "Hide"
    }

    option "true" {
      label = "Show"
    }
  }

  container {

    card {
      width = 2
      query = query.organizations_root_organizational_unit_count
      args  = [self.input.root_arn.value]
    }

    card {
      width = 2
      query = query.organizations_root_account_count
      args  = [self.input.root_arn.value]
    }

    card {
      width = 2
      query = query.organizations_root_policy_type_count
      args  = [self.input.root_arn.value]
    }

  }

  with "organizations_accounts_for_organizations_root" {
    query = query.organizations_accounts_for_organizations_root
    args  = [self.input.root_arn.value]
  }

  with "organizations_organizational_units_for_organizations_root" {
    query = query.organizations_organizational_units_for_organizations_root
    args  = [self.input.root_arn.value]
  }

  with "organizations_targets_for_organizations_root" {
    query = query.organizations_targets_for_organizations_root
    args  = [self.input.root_arn.value]
  }

  with "organizations_policy_attachments_for_organizations_root" {
    query = query.organizations_policy_attachments_for_targets
    args  = [with.organizations_targets_for_organizations_root.rows[*].target_arn]
  }

  with "organizations_policies_for_organizations_root" {
    query = query.organizations_policies_for_organizations_root
    args  = [with.organizations_policy_attachments_for_organizations_root.rows[0].attachments, self.input.aws_managed.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.organizations_root
        args = {
          organizations_root_arns = [self.input.root_arn.value]
        }
      }

      node {
        base = node.organizations_organizational_unit
        args = {
          organizations_organizational_unit_arns = with.organizations_organizational_units_for_organizations_root.rows[*].organizational_unit_arn
        }
      }

      node {
        base = node.organizations_account
        args = {
          organizations_account_arns = with.organizations_accounts_for_organizations_root.rows[*].account_arn
        }
      }

      node {
        base = node.organizations_service_control_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_root.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_resource_control_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_root.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_declarative_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_root.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_tag_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_root.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_backup_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_root.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_aiservices_opt_out_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_root.rows[*].policy_arn
        }
      }

      edge {
        base = edge.organizations_parent_to_organizational_unit
        args = {
          organizations_organizational_unit_arns = with.organizations_organizational_units_for_organizations_root.rows[*].organizational_unit_arn
        }
      }

      edge {
        base = edge.organizations_parent_to_account
        args = {
          organizations_account_arns = with.organizations_accounts_for_organizations_root.rows[*].account_arn
        }
      }

      edge {
        base = edge.organizations_target_to_policy
        args = {
          organizations_policy_attachments = with.organizations_policy_attachments_for_organizations_root.rows[0].attachments
          organizations_policy_arns = with.organizations_policies_for_organizations_root.rows[*].policy_arn
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
        query = query.organizations_root_overview
        args  = [self.input.root_arn.value]
      }

      table {
        title = "Policy Types"
        width = 6
        query = query.organizations_root_policy_types
        args  = [self.input.root_arn.value]
      }

    }

    container {
      width = 6

      hierarchy {
        title = "Organization Structure"
        type  = "tree"
        query = query.organizations_root_hierarchy
        args  = [self.input.root_arn.value]

        category "root" {
          color = local.management_governance_color
        }

        category "organizational_unit" {
          color = local.management_governance_color
        }

        category "account" {
          color = local.management_governance_color
        }
      }

    }

  }

  container {

    table {
      title = "Policy Attachments"
      query = query.organizations_root_policy_attachments
      args  = [with.organizations_policy_attachments_for_organizations_root.rows[0].attachments]

      column "Policy ARN" {
        display = "none"
      }

      column "Policy" {
        href = "/aws_insights.dashboard.organizations_policy_detail?input.policy_arn={{.'Policy ARN' | @uri}}"
      }
    }

  }

}

# Input queries

query "organizations_root_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'organization_id', split_part(arn, '/', 2),
        'account_id', account_id
      ) as tags
    from
      aws_organizations_root
    order by
      title;
  EOQ
}

# With queries

query "organizations_accounts_for_organizations_root" {
  sql = <<-EOQ
    select
      arn as account_arn
    from
      aws_organizations_account
    where
      split_part(arn, '/', 2) = split_part($1, '/', 2);
  EOQ
}

query "organizations_organizational_units_for_organizations_root" {
  sql = <<-EOQ
    select
      arn as organizational_unit_arn
    from
      aws_organizations_organizational_unit
    where
      split_part(arn, '/', 2) = split_part($1, '/', 2);
  EOQ
}

query "organizations_targets_for_organizations_root" {
  sql = <<-EOQ
    select
      arn as target_arn
    from
      aws_organizations_root
    where
      arn = $1
    union all
    select
      arn
    from
      aws_organizations_organizational_unit
    where
      split_part(arn, '/', 2) = split_part($1, '/', 2)
    union all
    select
      arn
    from
      aws_organizations_account
    where
      split_part(arn, '/', 2) = split_part($1, '/', 2);
  EOQ
}

query "organizations_policies_for_organizations_root" {
  sql = <<-EOQ
    select
      distinct policy_arn
    from
      (${local.organizations_policy_attachments_sql}) as policies
    where
      not aws_managed
      or $2::bool;
  EOQ
}

# Card queries

query "organizations_root_organizational_unit_count" {
  sql = <<-EOQ
    select
      'Organizational Units' as label,
      count(*) as value
    from
      aws_organizations_organizational_unit
    where
      split_part(arn, '/', 2) = split_part($1, '/', 2);
  EOQ
}

query "organizations_root_account_count" {
  sql = <<-EOQ
    select
      'Accounts' as label,
      count(*) as value
    from
      aws_organizations_account
    where
      split_part(arn, '/', 2) = split_part($1, '/', 2);
  EOQ
}

query "organizations_root_policy_type_count" {
  sql = <<-EOQ
    select
      'Enabled Policy Types' as label,
      count(*) as value
    from
      aws_organizations_root,
      jsonb_array_elements(policy_types) as t
    where
      arn = $1
      and t ->> 'Status' = 'ENABLED';
  EOQ
}

# Other detail page queries

query "organizations_root_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      id as "ID",
      split_part(arn, '/', 2) as "Organization ID",
      account_id as "Management Account ID",
      arn as "ARN"
    from
      aws_organizations_root
    where
      arn = $1;
  EOQ
}

query "organizations_root_policy_types" {
  sql = <<-EOQ
    select
      t ->> 'Type' as "Type",
      t ->> 'Status' as "Status"
    from
      aws_organizations_root,
      jsonb_array_elements(policy_types) as t
    where
      arn = $1
    order by
      t ->> 'Type';
  EOQ
}

query "organizations_root_hierarchy" {
  sql = <<-EOQ
    select
      arn as id,
      name as title,
      'root' as category,
      null as from_id
    from
      aws_organizations_root
    where
      arn = $1
    union all
    select
      ou.arn as id,
      ou.name as title,
      'organizational_unit' as category,
      coalesce(parent_ou.arn, r.arn) as from_id
    from
      aws_organizations_organizational_unit as ou
      left join aws_organizations_organizational_unit as parent_ou on parent_ou.id = ou.parent_id
      left join aws_organizations_root as r on r.id = ou.parent_id
    where
      split_part(ou.arn, '/', 2) = split_part($1, '/', 2)
    union all
    select
      a.arn as id,
      a.name || ' (' || a.id || ')' as title,
      'account' as category,
      coalesce(parent_ou.arn, r.arn) as from_id
    from
      aws_organizations_account as a
      left join aws_organizations_organizational_unit as parent_ou on parent_ou.id = a.parent_id
      left join aws_organizations_root as r on r.id = a.parent_id
    where
      split_part(a.arn, '/', 2) = split_part($1, '/', 2);
  EOQ
}

query "organizations_root_policy_attachments" {
  sql = <<-EOQ
    select
      target_name as "Target",
      target_type as "Target Type",
      policy_name as "Policy",
      type as "Policy Type",
      aws_managed as "AWS Managed",
      policy_arn as "Policy ARN"
    from
      (${local.organizations_policy_attachments_sql}) as policies
    order by
      depth,
      target_name,
      type,
      policy_name;
  EOQ
}
