dashboard "organizations_organizational_unit_detail" {

  title         = "AWS Organizations Organizational Unit Detail"
  documentation = file("./dashboards/organizations/docs/organizations_organizational_unit_detail.md")

  tags = merge(local.organizations_common_tags, {
    type = "Detail"
  })

  input "organizational_unit_arn" {
    title = "Select an organizational unit:"
    query = query.organizations_organizational_unit_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.organizations_organizational_unit_child_organizational_unit_count
      args  = [self.input.organizational_unit_arn.value]
    }

    card {
      width = 2
      query = query.organizations_organizational_unit_account_count
      args  = [self.input.organizational_unit_arn.value]
    }

    card {
      width = 2
      query = query.organizations_organizational_unit_service_control_policy_count
      args  = [with.organizations_policy_attachments_for_organizations_organizational_unit.rows[0].attachments, with.organizations_path_targets_for_organizations_organizational_unit.rows[*].target_arn]
    }

    card {
      width = 2
      query = query.organizations_organizational_unit_resource_control_policy_count
      args  = [with.organizations_policy_attachments_for_organizations_organizational_unit.rows[0].attachments, with.organizations_path_targets_for_organizations_organizational_unit.rows[*].target_arn]
    }

  }

  with "organizations_path_targets_for_organizations_organizational_unit" {
    query = query.organizations_path_targets_for_organizations_organizational_unit
    args  = [self.input.organizational_unit_arn.value]
  }

  with "organizations_targets_for_organizations_organizational_unit" {
    query = query.organizations_targets_for_organizations_organizational_unit
    args  = [self.input.organizational_unit_arn.value]
  }

  with "organizations_policy_attachments_for_organizations_organizational_unit" {
    query = query.organizations_policy_attachments_for_targets
    args  = [with.organizations_targets_for_organizations_organizational_unit.rows[*].target_arn]
  }

  with "organizations_policies_for_organizations_organizational_unit" {
    query = query.organizations_policies_for_organizations_organizational_unit
    args  = [with.organizations_policy_attachments_for_organizations_organizational_unit.rows[0].attachments]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.organizations_root
        args = {
          organizations_root_arns = with.organizations_targets_for_organizations_organizational_unit.rows[*].target_arn
        }
      }

      node {
        base = node.organizations_organizational_unit
        args = {
          organizations_organizational_unit_arns = with.organizations_targets_for_organizations_organizational_unit.rows[*].target_arn
        }
      }

      node {
        base = node.organizations_account
        args = {
          organizations_account_arns = with.organizations_targets_for_organizations_organizational_unit.rows[*].target_arn
        }
      }

      node {
        base = node.organizations_service_control_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_organizational_unit.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_resource_control_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_organizational_unit.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_declarative_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_organizational_unit.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_tag_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_organizational_unit.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_backup_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_organizational_unit.rows[*].policy_arn
        }
      }

      node {
        base = node.organizations_aiservices_opt_out_policy
        args = {
          organizations_policy_arns = with.organizations_policies_for_organizations_organizational_unit.rows[*].policy_arn
        }
      }

      edge {
        base = edge.organizations_parent_to_organizational_unit
        args = {
          organizations_organizational_unit_arns = with.organizations_targets_for_organizations_organizational_unit.rows[*].target_arn
        }
      }

      edge {
        base = edge.organizations_parent_to_account
        args = {
          organizations_account_arns = with.organizations_targets_for_organizations_organizational_unit.rows[*].target_arn
        }
      }

      edge {
        base = edge.organizations_target_to_policy
        args = {
          organizations_policy_attachments = with.organizations_policy_attachments_for_organizations_organizational_unit.rows[0].attachments
          organizations_policy_arns = with.organizations_policies_for_organizations_organizational_unit.rows[*].policy_arn
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
        query = query.organizations_organizational_unit_overview
        args  = [self.input.organizational_unit_arn.value]
      }

      table {
        title = "Children"
        width = 6
        query = query.organizations_organizational_unit_children
        args  = [self.input.organizational_unit_arn.value]

        column "ARN" {
          display = "none"
        }

        column "Detail Path" {
          display = "none"
        }

        column "Name" {
          href = "{{.'Detail Path'}}{{.ARN | @uri}}"
        }
      }

    }

    container {
      width = 6

      table {
        title = "Effective Policies"
        query = query.organizations_organizational_unit_effective_policies
        args  = [with.organizations_policy_attachments_for_organizations_organizational_unit.rows[0].attachments, with.organizations_path_targets_for_organizations_organizational_unit.rows[*].target_arn]

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

query "organizations_organizational_unit_input" {
  sql = <<-EOQ
    select
      name as label,
      arn as value,
      json_build_object(
        'id', id,
        'account_id', account_id
      ) as tags
    from
      aws_organizations_organizational_unit
    order by
      name;
  EOQ
}

# With queries

# The root, the organizational units above this one, and the organizational unit itself.
query "organizations_path_targets_for_organizations_organizational_unit" {
  sql = <<-EOQ
    select
      r.arn as target_arn
    from
      aws_organizations_root as r
    where
      split_part(r.arn, '/', 2) = split_part($1, '/', 2)
    union all
    select
      ou.arn
    from
      aws_organizations_organizational_unit as self
      join aws_organizations_organizational_unit as ou on ou.path @> self.path
    where
      self.arn = $1;
  EOQ
}

# The path targets above, plus the organizational units and accounts directly below this one.
query "organizations_targets_for_organizations_organizational_unit" {
  sql = <<-EOQ
    select
      r.arn as target_arn
    from
      aws_organizations_root as r
    where
      split_part(r.arn, '/', 2) = split_part($1, '/', 2)
    union all
    select
      ou.arn
    from
      aws_organizations_organizational_unit as self
      join aws_organizations_organizational_unit as ou on ou.path @> self.path
    where
      self.arn = $1
    union all
    select
      child.arn
    from
      aws_organizations_organizational_unit as self
      join aws_organizations_organizational_unit as child on child.parent_id = self.id
    where
      self.arn = $1
    union all
    select
      a.arn
    from
      aws_organizations_organizational_unit as self
      join aws_organizations_account as a on a.parent_id = self.id
    where
      self.arn = $1;
  EOQ
}

query "organizations_policies_for_organizations_organizational_unit" {
  sql = <<-EOQ
    select
      distinct policy_arn
    from
      (${local.organizations_policy_attachments_sql}) as policies;
  EOQ
}

# Card queries

query "organizations_organizational_unit_child_organizational_unit_count" {
  sql = <<-EOQ
    select
      'Child Organizational Units' as label,
      count(child.id) as value
    from
      aws_organizations_organizational_unit as self
      left join aws_organizations_organizational_unit as child on child.parent_id = self.id
    where
      self.arn = $1;
  EOQ
}

query "organizations_organizational_unit_account_count" {
  sql = <<-EOQ
    select
      'Accounts' as label,
      count(a.id) as value
    from
      aws_organizations_organizational_unit as self
      left join aws_organizations_account as a on a.parent_id = self.id
    where
      self.arn = $1;
  EOQ
}

query "organizations_organizational_unit_service_control_policy_count" {
  sql = <<-EOQ
    select
      'Effective SCPs' as label,
      count(distinct policy_arn) as value
    from
      (${local.organizations_policy_attachments_sql}) as policies
    where
      target_arn = any($2)
      and type = 'SERVICE_CONTROL_POLICY';
  EOQ
}

query "organizations_organizational_unit_resource_control_policy_count" {
  sql = <<-EOQ
    select
      'Effective RCPs' as label,
      count(distinct policy_arn) as value
    from
      (${local.organizations_policy_attachments_sql}) as policies
    where
      target_arn = any($2)
      and type = 'RESOURCE_CONTROL_POLICY';
  EOQ
}

# Other detail page queries

query "organizations_organizational_unit_overview" {
  sql = <<-EOQ
    with path as (
      select
        string_agg(ou.name, ' / ' order by nlevel(ou.path)) as ou_path
      from
        aws_organizations_organizational_unit as self
        join aws_organizations_organizational_unit as ou on ou.path @> self.path
      where
        self.arn = $1
    )
    select
      self.name as "Name",
      self.id as "ID",
      'Root / ' || path.ou_path as "Path",
      self.parent_id as "Parent ID",
      self.arn as "ARN"
    from
      aws_organizations_organizational_unit as self,
      path
    where
      self.arn = $1;
  EOQ
}

query "organizations_organizational_unit_children" {
  sql = <<-EOQ
    select
      child.name as "Name",
      child.id as "ID",
      'Organizational Unit' as "Type",
      child.arn as "ARN",
      '/aws_insights.dashboard.organizations_organizational_unit_detail?input.organizational_unit_arn=' as "Detail Path"
    from
      aws_organizations_organizational_unit as self
      join aws_organizations_organizational_unit as child on child.parent_id = self.id
    where
      self.arn = $1
    union all
    select
      a.name,
      a.id,
      'Account',
      a.arn,
      '/aws_insights.dashboard.organizations_account_detail?input.account_arn='
    from
      aws_organizations_organizational_unit as self
      join aws_organizations_account as a on a.parent_id = self.id
    where
      self.arn = $1
    order by
      "Type" desc,
      "Name";
  EOQ
}

query "organizations_organizational_unit_effective_policies" {
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
    where
      target_arn = any($2)
    order by
      depth,
      type,
      policy_name;
  EOQ
}
