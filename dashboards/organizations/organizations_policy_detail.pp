dashboard "organizations_policy_detail" {

  title         = "AWS Organizations Policy Detail"
  documentation = file("./dashboards/organizations/docs/organizations_policy_detail.md")

  tags = merge(local.organizations_common_tags, {
    type = "Detail"
  })

  input "policy_arn" {
    title = "Select a policy:"
    query = query.organizations_policy_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.organizations_policy_type
      args  = [self.input.policy_arn.value]
    }

    card {
      width = 2
      query = query.organizations_policy_aws_managed
      args  = [self.input.policy_arn.value]
    }

    card {
      width = 2
      query = query.organizations_policy_target_count
      args  = [with.organizations_targets_for_organizations_policy.rows[*].target_arn]
    }

    card {
      width = 2
      query = query.organizations_policy_account_count
      args  = [with.organizations_targets_for_organizations_policy.rows[*].target_arn]
    }

    card {
      width = 2
      query = query.organizations_policy_statement_count
      args  = [self.input.policy_arn.value]
    }

    card {
      width = 2
      query = query.organizations_policy_size
      args  = [self.input.policy_arn.value]
    }

  }

  with "organizations_targets_for_organizations_policy" {
    query = query.organizations_targets_for_organizations_policy
    args  = [self.input.policy_arn.value]
  }

  with "organizations_organizational_units_for_organizations_policy" {
    query = query.organizations_organizational_units_for_organizations_policy
    args  = [with.organizations_targets_for_organizations_policy.rows[*].target_arn]
  }

  with "organizations_accounts_for_organizations_policy" {
    query = query.organizations_accounts_for_organizations_policy
    args  = [with.organizations_targets_for_organizations_policy.rows[*].target_arn]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.organizations_service_control_policy
        args = {
          organizations_policy_arns = [self.input.policy_arn.value]
        }
      }

      node {
        base = node.organizations_resource_control_policy
        args = {
          organizations_policy_arns = [self.input.policy_arn.value]
        }
      }

      node {
        base = node.organizations_declarative_policy
        args = {
          organizations_policy_arns = [self.input.policy_arn.value]
        }
      }

      node {
        base = node.organizations_tag_policy
        args = {
          organizations_policy_arns = [self.input.policy_arn.value]
        }
      }

      node {
        base = node.organizations_backup_policy
        args = {
          organizations_policy_arns = [self.input.policy_arn.value]
        }
      }

      node {
        base = node.organizations_aiservices_opt_out_policy
        args = {
          organizations_policy_arns = [self.input.policy_arn.value]
        }
      }

      node {
        base = node.organizations_root
        args = {
          organizations_root_arns = with.organizations_targets_for_organizations_policy.rows[*].target_arn
        }
      }

      node {
        base = node.organizations_organizational_unit
        args = {
          organizations_organizational_unit_arns = with.organizations_organizational_units_for_organizations_policy.rows[*].organizational_unit_arn
        }
      }

      node {
        base = node.organizations_account
        args = {
          organizations_account_arns = with.organizations_accounts_for_organizations_policy.rows[*].account_arn
        }
      }

      edge {
        base = edge.organizations_attached_target_to_policy
        args = {
          organizations_target_arns = with.organizations_targets_for_organizations_policy.rows[*].target_arn
          organizations_policy_arns = [self.input.policy_arn.value]
        }
      }

      edge {
        base = edge.organizations_parent_to_organizational_unit
        args = {
          organizations_organizational_unit_arns = with.organizations_organizational_units_for_organizations_policy.rows[*].organizational_unit_arn
        }
      }

      edge {
        base = edge.organizations_parent_to_account
        args = {
          organizations_account_arns = with.organizations_accounts_for_organizations_policy.rows[*].account_arn
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
        query = query.organizations_policy_overview
        args  = [self.input.policy_arn.value]
      }

      table {
        title = "Targets"
        width = 6
        query = query.organizations_policy_targets
        args  = [with.organizations_targets_for_organizations_policy.rows[*].target_arn]

        column "ARN" {
          display = "none"
        }

        column "Detail Path" {
          display = "none"
        }

        column "Target" {
          href = "{{.'Detail Path'}}{{.ARN | @uri}}"
        }
      }

    }

    container {
      width = 6

      table {
        title = "Affected Accounts"
        query = query.organizations_policy_affected_accounts
        args  = [with.organizations_targets_for_organizations_policy.rows[*].target_arn]

        column "ARN" {
          display = "none"
        }

        column "Account" {
          href = "/aws_insights.dashboard.organizations_account_detail?input.account_arn={{.ARN | @uri}}"
        }
      }

    }

  }

  container {

    table {
      title = "Policy Statements"
      query = query.organizations_policy_statements
      args  = [self.input.policy_arn.value]

      column "Action" {
        wrap = "all"
      }

      column "NotAction" {
        wrap = "all"
      }

      column "Resource" {
        wrap = "all"
      }

      column "Condition" {
        wrap = "all"
      }
    }

  }

}

# Input queries

query "organizations_policy_input" {
  sql = <<-EOQ
    with policies as (
      select
        name,
        arn,
        type,
        aws_managed,
        account_id
      from
        aws_organizations_policy
      where
        type in (
          'SERVICE_CONTROL_POLICY',
          'RESOURCE_CONTROL_POLICY',
          'DECLARATIVE_POLICY_EC2',
          'TAG_POLICY',
          'BACKUP_POLICY',
          'AISERVICES_OPT_OUT_POLICY'
        )
    )
    select
      distinct on (arn)
      name as label,
      arn as value,
      json_build_object(
        'type', type,
        'account_id', case when aws_managed then 'AWS Managed' else account_id end
      ) as tags
    from
      policies
    order by
      arn,
      label;
  EOQ
}

# With queries

# Targets the policy is directly attached to. The policy type is part of the policy ARN, e.g.
# arn:aws:organizations::123456789012:policy/o-exampleorgid/service_control_policy/p-examplepolicyid
query "organizations_targets_for_organizations_policy" {
  sql = <<-EOQ
    with targets as (
      select
        id,
        arn
      from
        aws_organizations_root
      union all
      select
        id,
        arn
      from
        aws_organizations_organizational_unit
      union all
      select
        id,
        arn
      from
        aws_organizations_account
    )
    select
      t.arn as target_arn
    from
      targets as t
      join aws_organizations_policy_target as p on p.target_id = t.id and p.type = upper(split_part($1, '/', -2))
    where
      p.arn = $1;
  EOQ
}

# Organizational units the policy is attached to, and every organizational unit below them.
query "organizations_organizational_units_for_organizations_policy" {
  sql = <<-EOQ
    select
      ou.arn as organizational_unit_arn
    from
      aws_organizations_organizational_unit as ou
    where
      exists (
        select
          1
        from
          aws_organizations_root as r
        where
          r.arn = any($1)
      )
      or exists (
        select
          1
        from
          aws_organizations_organizational_unit as attached
        where
          attached.arn = any($1)
          and attached.path @> ou.path
      );
  EOQ
}

# Accounts the policy is attached to directly, or inherits from the root or an organizational unit.
query "organizations_accounts_for_organizations_policy" {
  sql = <<-EOQ
    select
      account_arn
    from
      (${local.organizations_policy_affected_accounts_sql}) as affected;
  EOQ
}

# Card queries

query "organizations_policy_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      replace(initcap(replace(lower(split_part($1, '/', -2)), '_', ' ')), 'Ec2', 'EC2') as value;
  EOQ
}

query "organizations_policy_aws_managed" {
  sql = <<-EOQ
    select
      'Managed By' as label,
      case when split_part($1, ':', 5) = 'aws' then 'AWS' else 'Customer' end as value;
  EOQ
}

query "organizations_policy_target_count" {
  sql = <<-EOQ
    select
      'Attached Targets' as label,
      cardinality($1::text[]) as value,
      case when cardinality($1::text[]) = 0 then 'alert' else 'ok' end as type;
  EOQ
}

query "organizations_policy_account_count" {
  sql = <<-EOQ
    select
      'Affected Accounts' as label,
      count(*) as value
    from
      (${local.organizations_policy_affected_accounts_sql}) as affected;
  EOQ
}

query "organizations_policy_statement_count" {
  sql = <<-EOQ
    select
      'Statements' as label,
      case jsonb_typeof(content -> 'Statement')
        when 'array' then jsonb_array_length(content -> 'Statement')
        when 'object' then 1
        else 0
      end as value
    from
      aws_organizations_policy
    where
      type = upper(split_part($1, '/', -2))
      and arn = $1
    limit 1;
  EOQ
}

# Policy size limits: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_limits.html
query "organizations_policy_size" {
  sql = <<-EOQ
    with policy as (
      select
        length(regexp_replace(content::text, '\s', '', 'g')) as size,
        case type
          when 'SERVICE_CONTROL_POLICY' then 10240
          when 'RESOURCE_CONTROL_POLICY' then 5120
        end as max_size
      from
        aws_organizations_policy
      where
        type = upper(split_part($1, '/', -2))
        and arn = $1
      limit 1
    )
    select
      'Size (Characters)' as label,
      case when max_size is null then size::text else size || ' / ' || max_size end as value,
      case when size >= 0.9 * max_size then 'alert' else 'info' end as type
    from
      policy;
  EOQ
}

# Other detail page queries

query "organizations_policy_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      id as "ID",
      type as "Type",
      aws_managed as "AWS Managed",
      description as "Description",
      arn as "ARN"
    from
      aws_organizations_policy
    where
      type = upper(split_part($1, '/', -2))
      and arn = $1
    limit 1;
  EOQ
}

query "organizations_policy_targets" {
  sql = <<-EOQ
    with targets as (
      select
        id,
        arn,
        name,
        'Root' as target_type,
        0 as depth
      from
        aws_organizations_root
      where
        arn = any($1)
      union all
      select
        id,
        arn,
        name,
        'Organizational Unit',
        nlevel(path) - 1
      from
        aws_organizations_organizational_unit
      where
        arn = any($1)
      union all
      select
        id,
        arn,
        name,
        'Account',
        99
      from
        aws_organizations_account
      where
        arn = any($1)
    )
    select
      name as "Target",
      id as "ID",
      target_type as "Target Type",
      arn as "ARN",
      case target_type
        when 'Root' then '/aws_insights.dashboard.organizations_root_detail?input.root_arn='
        when 'Organizational Unit' then '/aws_insights.dashboard.organizations_organizational_unit_detail?input.organizational_unit_arn='
        else '/aws_insights.dashboard.organizations_account_detail?input.account_arn='
      end as "Detail Path"
    from
      targets
    order by
      depth,
      name;
  EOQ
}

query "organizations_policy_affected_accounts" {
  sql = <<-EOQ
    select
      a.name as "Account",
      a.id as "Account ID",
      affected.inherited_from as "Attached At",
      a.arn as "ARN"
    from
      (${local.organizations_policy_affected_accounts_sql}) as affected
      join aws_organizations_account as a on a.arn = affected.account_arn
    order by
      a.name;
  EOQ
}

query "organizations_policy_statements" {
  sql = <<-EOQ
    with policy as (
      select
        content
      from
        aws_organizations_policy
      where
        type = upper(split_part($1, '/', -2))
        and arn = $1
      limit 1
    )
    select
      coalesce(s ->> 'Sid', concat('[', i::text, ']')) as "Sid",
      s ->> 'Effect' as "Effect",
      s -> 'Action' as "Action",
      s -> 'NotAction' as "NotAction",
      coalesce(s -> 'Resource', s -> 'NotResource') as "Resource",
      s -> 'Condition' as "Condition"
    from
      policy,
      jsonb_array_elements(
        case jsonb_typeof(content -> 'Statement')
          when 'array' then content -> 'Statement'
          when 'object' then jsonb_build_array(content -> 'Statement')
          else '[]'::jsonb
        end
      ) with ordinality as t(s, i)
    order by
      i;
  EOQ
}

locals {
  # Accounts the policy applies to, given the targets it's attached to ($1): accounts it's attached
  # to directly, accounts below an organizational unit it's attached to, or every account when it's
  # attached to the root.
  organizations_policy_affected_accounts_sql = <<-EOQ
    with attached as (
      select
        id,
        name,
        'root' as target_type
      from
        aws_organizations_root
      where
        arn = any($1)
      union all
      select
        id,
        name,
        'organizational_unit'
      from
        aws_organizations_organizational_unit
      where
        arn = any($1)
      union all
      select
        id,
        name,
        'account'
      from
        aws_organizations_account
      where
        arn = any($1)
    ),
    account_paths as (
      select
        a.arn,
        a.id,
        ou.path
      from
        aws_organizations_account as a
        left join aws_organizations_organizational_unit as ou on ou.id = a.parent_id
    )
    select
      ap.arn as account_arn,
      string_agg(at.name, ', ' order by at.target_type desc) as inherited_from
    from
      account_paths as ap
      join attached as at on
        at.target_type = 'root'
        or (at.target_type = 'account' and at.id = ap.id)
        or (
          at.target_type = 'organizational_unit'
          and ap.path is not null
          and ap.path ~ ('*.' || replace(at.id, '-', '_') || '.*')::lquery
        )
    group by
      ap.arn
  EOQ
}
