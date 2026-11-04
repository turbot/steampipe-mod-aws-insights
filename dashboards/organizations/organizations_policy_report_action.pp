dashboard "organizations_policy_action_report" {

  title         = "AWS Organizations Policy Action Report"
  documentation = file("./dashboards/organizations/docs/organizations_policy_report_action.md")

  tags = merge(local.organizations_common_tags, {
    type = "Report"
  })

  input "account_arn" {
    title = "Select an account:"
    query = query.organizations_account_input
    width = 4
  }

  input "action" {
    title       = "Enter an action:"
    type        = "text"
    width       = 4
    placeholder = "e.g. s3:PutBucketPolicy"
  }

  with "organizations_targets_for_organizations_account" {
    query = query.organizations_targets_for_organizations_account
    args  = [self.input.account_arn.value]
  }

  with "organizations_policy_attachments_for_organizations_account" {
    query = query.organizations_policy_attachments_for_targets
    args  = [with.organizations_targets_for_organizations_account.rows[*].target_arn]
  }

  container {

    card {
      width = 3
      query = query.organizations_policy_action_service_control_policy_result
      args  = [with.organizations_policy_attachments_for_organizations_account.rows[0].attachments, self.input.action.value]
    }

    card {
      width = 3
      query = query.organizations_policy_action_resource_control_policy_result
      args  = [with.organizations_policy_attachments_for_organizations_account.rows[0].attachments, self.input.action.value]
    }

  }

  container {

    table {
      title = "Allow by Level"
      width = 4
      query = query.organizations_policy_action_allow_by_level
      args  = [with.organizations_policy_attachments_for_organizations_account.rows[0].attachments, self.input.action.value]
    }

    table {
      title = "Matching Customer Managed Statements"
      width = 8
      query = query.organizations_policy_action_matching_statements
      args  = [with.organizations_policy_attachments_for_organizations_account.rows[0].attachments, self.input.action.value]

      column "Policy ARN" {
        display = "none"
      }

      column "Policy" {
        href = "${dashboard.organizations_policy_detail.url_path}?input.policy_arn={{.'Policy ARN' | @uri}}"
      }

      column "Condition" {
        wrap = "all"
      }
    }

  }

}

# Card queries

query "organizations_policy_action_service_control_policy_result" {
  sql = <<-EOQ
    with statements as (
      ${local.organizations_policy_action_statements_sql}
    ),
    levels as (
      select
        target_arn,
        target_name,
        depth,
        bool_or(effect = 'Allow' and type = 'SERVICE_CONTROL_POLICY') as allowed
      from
        statements
      group by
        target_arn,
        target_name,
        depth
    ),
    result as (
      select
        case
          when exists (select 1 from aws_organizations_account as a join statements as s on s.target_arn = a.arn where a.id = a.account_id) then 'Not applied (management account)'
          when exists (select 1 from statements where effect = 'Deny' and type = 'SERVICE_CONTROL_POLICY' and condition is null) then 'Denied'
          when exists (select 1 from levels where not allowed) then 'Denied (no allow at ' || (select string_agg(target_name, ', ' order by depth) from levels where not allowed) || ')'
          when exists (select 1 from statements where effect = 'Deny' and type = 'SERVICE_CONTROL_POLICY') then 'Conditionally denied'
          else 'Allowed'
        end as value
    )
    select
      'Service Control Policies' as label,
      value,
      'info' as type
    from
      result;
  EOQ
}

query "organizations_policy_action_resource_control_policy_result" {
  sql = <<-EOQ
    with statements as (
      ${local.organizations_policy_action_statements_sql}
    ),
    result as (
      select
        case
          when exists (select 1 from aws_organizations_account as a join statements as s on s.target_arn = a.arn where a.id = a.account_id) then 'Not applied (management account)'
          when exists (select 1 from statements where effect = 'Deny' and type = 'RESOURCE_CONTROL_POLICY' and condition is null) then 'Denied'
          when exists (select 1 from statements where effect = 'Deny' and type = 'RESOURCE_CONTROL_POLICY') then 'Conditionally denied'
          else 'Not denied'
        end as value
    )
    select
      'Resource Control Policies' as label,
      value,
      'info' as type
    from
      result;
  EOQ
}

# Table queries

query "organizations_policy_action_allow_by_level" {
  sql = <<-EOQ
    with statements as (
      ${local.organizations_policy_action_statements_sql}
    ),
    levels as (
      select
        distinct target_arn,
        target_name,
        depth
      from
        (${local.organizations_policy_attachments_sql}) as attachments
      where
        type = 'SERVICE_CONTROL_POLICY'
    )
    select
      l.target_name as "Level",
      coalesce(
        string_agg(distinct s.policy_name, ', ') filter (where s.effect = 'Allow' and s.type = 'SERVICE_CONTROL_POLICY'),
        'None'
      ) as "Allowed By"
    from
      levels as l
      left join statements as s on s.target_arn = l.target_arn
    group by
      l.target_name,
      l.depth
    order by
      l.depth;
  EOQ
}

query "organizations_policy_action_matching_statements" {
  sql = <<-EOQ
    select
      target_name as "Attached To",
      policy_name as "Policy",
      type as "Policy Type",
      sid as "Sid",
      effect as "Effect",
      matched_on as "Matched On",
      condition as "Condition",
      policy_arn as "Policy ARN"
    from
      (${local.organizations_policy_action_statements_sql}) as statements
    where
      not aws_managed
    order by
      depth,
      type,
      effect desc,
      policy_name;
  EOQ
}

locals {
  # Statements in the service and resource control policies attached along an account's path
  # ($1, the attachments from query.organizations_policy_attachments_for_targets) that match an
  # action ($2). Statements match on Action patterns (with * and ? wildcards), or on NotAction
  # when no NotAction pattern matches.
  organizations_policy_action_statements_sql = <<-EOQ
    with policies as (
      select
        distinct *
      from
        (${local.organizations_policy_attachments_sql}) as policies
      where
        type in ('SERVICE_CONTROL_POLICY', 'RESOURCE_CONTROL_POLICY')
    ),
    contents as (
      select
        distinct on (arn)
        arn,
        content
      from
        aws_organizations_policy
      where
        type in ('SERVICE_CONTROL_POLICY', 'RESOURCE_CONTROL_POLICY')
    ),
    statements as (
      select
        p.target_arn,
        p.target_name,
        p.depth,
        p.policy_name,
        p.policy_arn,
        p.type,
        p.aws_managed,
        coalesce(s ->> 'Sid', concat('[', i::text, ']')) as sid,
        s ->> 'Effect' as effect,
        case jsonb_typeof(s -> 'Action')
          when 'array' then s -> 'Action'
          when 'string' then jsonb_build_array(s -> 'Action')
        end as actions,
        case jsonb_typeof(s -> 'NotAction')
          when 'array' then s -> 'NotAction'
          when 'string' then jsonb_build_array(s -> 'NotAction')
        end as not_actions,
        s -> 'Condition' as condition
      from
        policies as p
        join contents as c on c.arn = p.policy_arn,
        jsonb_array_elements(
          case jsonb_typeof(c.content -> 'Statement')
            when 'array' then c.content -> 'Statement'
            else jsonb_build_array(c.content -> 'Statement')
          end
        ) with ordinality as t(s, i)
    )
    select
      target_arn,
      target_name,
      depth,
      policy_name,
      policy_arn,
      type,
      aws_managed,
      sid,
      effect,
      case when actions is not null then 'Action' else 'NotAction' end as matched_on,
      condition
    from
      statements
    where
      (
        actions is not null
        and exists (
          select
            1
          from
            jsonb_array_elements_text(actions) as a
          where
            lower($2) like replace(replace(lower(a), '*', '%'), '?', '_')
        )
      )
      or (
        not_actions is not null
        and not exists (
          select
            1
          from
            jsonb_array_elements_text(not_actions) as a
          where
            lower($2) like replace(replace(lower(a), '*', '%'), '?', '_')
        )
      )
  EOQ
}
