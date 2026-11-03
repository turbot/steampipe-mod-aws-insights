dashboard "organizations_dashboard" {

  title         = "AWS Organizations Dashboard"
  documentation = file("./dashboards/organizations/docs/organizations_dashboard.md")

  tags = merge(local.organizations_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.organizations_account_count
      width = 2
    }

    card {
      query = query.organizations_organizational_unit_count
      width = 2
    }

    card {
      query = query.organizations_service_control_policy_count
      width = 2
    }

    card {
      query = query.organizations_resource_control_policy_count
      width = 2
    }

    # Assessments
    card {
      query = query.organizations_policy_unattached_count
      width = 2
    }

    card {
      query = query.organizations_account_suspended_count
      width = 2
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Policy Attachment Status"
      query = query.organizations_policy_by_attachment_status
      type  = "donut"
      width = 4

      series "count" {
        point "attached" {
          color = "ok"
        }
        point "unattached" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Account Status"
      query = query.organizations_account_by_status
      type  = "donut"
      width = 4

      series "count" {
        point "active" {
          color = "ok"
        }
        point "suspended" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Member Account SCP Coverage"
      query = query.organizations_account_by_custom_service_control_policy
      type  = "donut"
      width = 4

      series "count" {
        point "custom scp" {
          color = "ok"
        }
        point "fullawsaccess only" {
          color = "alert"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Policies by Type"
      query = query.organizations_policy_by_type
      type  = "column"
      width = 4
    }

    chart {
      title = "Accounts by Organizational Unit"
      query = query.organizations_account_by_organizational_unit
      type  = "column"
      width = 4
    }

    chart {
      title = "Accounts by Joined Method"
      query = query.organizations_account_by_joined_method
      type  = "column"
      width = 4
    }

    table {
      title = "Service Control Policies per Target"
      query = query.organizations_service_control_policy_count_by_target
      width = 6
    }

    chart {
      title = "Accounts by Joined Age"
      query = query.organizations_account_by_joined_month
      type  = "column"
      width = 6
    }

  }

  container {

    table {
      title = "Policies"
      query = query.organizations_policy_attachment_summary

      column "ARN" {
        display = "none"
      }

      column "Name" {
        href = "/aws_insights.dashboard.organizations_policy_detail?input.policy_arn={{.ARN | @uri}}"
      }
    }

  }

}

# Card queries

query "organizations_account_count" {
  sql = <<-EOQ
    select
      count(*) as "Accounts"
    from
      aws_organizations_account;
  EOQ
}

query "organizations_organizational_unit_count" {
  sql = <<-EOQ
    select
      count(*) as "Organizational Units"
    from
      aws_organizations_organizational_unit;
  EOQ
}

query "organizations_service_control_policy_count" {
  sql = <<-EOQ
    select
      count(*) as "Service Control Policies"
    from
      aws_organizations_policy
    where
      type = 'SERVICE_CONTROL_POLICY'
      and not aws_managed;
  EOQ
}

query "organizations_resource_control_policy_count" {
  sql = <<-EOQ
    select
      count(*) as "Resource Control Policies"
    from
      aws_organizations_policy
    where
      type = 'RESOURCE_CONTROL_POLICY'
      and not aws_managed;
  EOQ
}

query "organizations_policy_unattached_count" {
  sql = <<-EOQ
    with attached as (
      ${local.organizations_all_target_policies_sql}
    )
    select
      count(*) as value,
      'Unattached Policies' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_organizations_policy as p
    where
      p.type in (
        'SERVICE_CONTROL_POLICY',
        'RESOURCE_CONTROL_POLICY',
        'DECLARATIVE_POLICY_EC2',
        'TAG_POLICY',
        'BACKUP_POLICY',
        'AISERVICES_OPT_OUT_POLICY'
      )
      and not p.aws_managed
      and p.arn not in (select policy_arn from attached);
  EOQ
}

query "organizations_account_suspended_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Suspended Accounts' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_organizations_account
    where
      status <> 'ACTIVE';
  EOQ
}

# Assessment queries

query "organizations_policy_by_attachment_status" {
  sql = <<-EOQ
    with attached as (
      ${local.organizations_all_target_policies_sql}
    ),
    policies as (
      select
        p.arn,
        p.arn in (select policy_arn from attached) as is_attached
      from
        aws_organizations_policy as p
      where
        p.type in (
          'SERVICE_CONTROL_POLICY',
          'RESOURCE_CONTROL_POLICY',
          'DECLARATIVE_POLICY_EC2',
          'TAG_POLICY',
          'BACKUP_POLICY',
          'AISERVICES_OPT_OUT_POLICY'
        )
        and not p.aws_managed
    )
    select
      case when is_attached then 'attached' else 'unattached' end as status,
      count(*)
    from
      policies
    group by
      status
    order by
      status;
  EOQ
}

query "organizations_account_by_status" {
  sql = <<-EOQ
    select
      lower(status) as status,
      count(*)
    from
      aws_organizations_account
    group by
      status
    order by
      status;
  EOQ
}

# Service control policies don't apply to the management account, so it's excluded.
query "organizations_account_by_custom_service_control_policy" {
  sql = <<-EOQ
    with attached as (
      ${local.organizations_all_target_policies_sql}
    ),
    custom_scp_targets as (
      select
        distinct target_arn
      from
        attached
      where
        type = 'SERVICE_CONTROL_POLICY'
        and not aws_managed
    ),
    account_targets as (
      select
        a.id as account_id,
        r.arn as target_arn
      from
        aws_organizations_account as a
        join aws_organizations_root as r on split_part(r.arn, '/', 2) = split_part(a.arn, '/', 2)
      where
        a.id <> a.account_id
      union all
      select
        a.id,
        ou.arn
      from
        aws_organizations_account as a
        join aws_organizations_organizational_unit as parent on parent.id = a.parent_id
        join aws_organizations_organizational_unit as ou on ou.path @> parent.path
      where
        a.id <> a.account_id
      union all
      select
        a.id,
        a.arn
      from
        aws_organizations_account as a
      where
        a.id <> a.account_id
    ),
    accounts as (
      select
        account_id,
        bool_or(target_arn in (select target_arn from custom_scp_targets)) as has_custom_scp
      from
        account_targets
      group by
        account_id
    )
    select
      case when has_custom_scp then 'custom scp' else 'fullawsaccess only' end as status,
      count(*)
    from
      accounts
    group by
      status
    order by
      status;
  EOQ
}

# Analysis queries

query "organizations_policy_by_type" {
  sql = <<-EOQ
    select
      replace(initcap(replace(lower(type), '_', ' ')), 'Ec2', 'EC2') as "Type",
      count(*) as "Policies"
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
      and not aws_managed
    group by
      type
    order by
      type;
  EOQ
}

query "organizations_account_by_organizational_unit" {
  sql = <<-EOQ
    select
      coalesce(ou.name, 'Root') as "Organizational Unit",
      count(a.id) as "Accounts"
    from
      aws_organizations_account as a
      left join aws_organizations_organizational_unit as ou on ou.id = a.parent_id
    group by
      ou.name
    order by
      ou.name nulls first;
  EOQ
}

query "organizations_account_by_joined_method" {
  sql = <<-EOQ
    select
      initcap(joined_method) as "Joined Method",
      count(*) as "Accounts"
    from
      aws_organizations_account
    group by
      joined_method
    order by
      joined_method;
  EOQ
}

# Service control policy quotas: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_limits.html
query "organizations_service_control_policy_count_by_target" {
  sql = <<-EOQ
    select
      target_name as "Target",
      count(*) as "Service Control Policies"
    from
      (${local.organizations_all_target_policies_sql}) as policies
    where
      type = 'SERVICE_CONTROL_POLICY'
    group by
      target_name,
      depth
    having
      count(*) > 1
    order by
      count(*) desc,
      depth,
      target_name;
  EOQ
}

query "organizations_account_by_joined_month" {
  sql = <<-EOQ
    with accounts as (
      select
        joined_timestamp
      from
        aws_organizations_account
    ),
    months as (
      select
        date_trunc('month', month) as month
      from
        generate_series(
          date_trunc('month', (select min(joined_timestamp) from accounts)),
          date_trunc('month', now()),
          interval '1 month'
        ) as month
    ),
    accounts_by_month as (
      select
        date_trunc('month', joined_timestamp) as month,
        count(*) as count
      from
        accounts
      group by
        month
    )
    select
      to_char(months.month, 'YYYY-MM') as "Month",
      coalesce(accounts_by_month.count, 0) as "Accounts"
    from
      months
      left join accounts_by_month on months.month = accounts_by_month.month
    order by
      months.month;
  EOQ
}

# Table queries

query "organizations_policy_attachment_summary" {
  sql = <<-EOQ
    with attached as (
      ${local.organizations_all_target_policies_sql}
    ),
    policies as (
      select
        distinct on (arn)
        name,
        arn,
        type,
        aws_managed,
        description,
        content
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
      p.name as "Name",
      p.type as "Type",
      p.aws_managed as "AWS Managed",
      count(a.target_arn) as "Attached Targets",
      string_agg(a.target_name, ', ' order by a.depth, a.target_name) as "Attached To",
      p.description as "Description",
      p.arn as "ARN"
    from
      policies as p
      left join attached as a on a.policy_arn = p.arn
    group by
      p.name,
      p.type,
      p.aws_managed,
      p.description,
      p.arn
    order by
      count(a.target_arn),
      p.type,
      p.name;
  EOQ
}
