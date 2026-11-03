locals {
  organizations_common_tags = {
    service = "AWS/Organizations"
  }
}

locals {
  # Policies attached directly to each target in the "targets" CTE. The
  # aws_organizations_policy_target table requires both target_id and type, so each policy type is
  # joined separately, and only when that type is enabled at the root, to keep the number of
  # ListPoliciesForTarget calls down.
  organizations_policies_for_targets_sql = <<-EOQ
    select
      t.*,
      p.name as policy_name,
      p.arn as policy_arn,
      p.type,
      p.aws_managed
    from
      targets as t
      join aws_organizations_policy_target as p on p.target_id = t.target_id and p.type = 'SERVICE_CONTROL_POLICY'
    where
      exists (
        select
          1
        from
          aws_organizations_root as r,
          jsonb_array_elements(r.policy_types) as pt
        where
          pt ->> 'Type' = 'SERVICE_CONTROL_POLICY'
          and pt ->> 'Status' = 'ENABLED'
      )
    union all
    select
      t.*,
      p.name,
      p.arn,
      p.type,
      p.aws_managed
    from
      targets as t
      join aws_organizations_policy_target as p on p.target_id = t.target_id and p.type = 'RESOURCE_CONTROL_POLICY'
    where
      exists (
        select
          1
        from
          aws_organizations_root as r,
          jsonb_array_elements(r.policy_types) as pt
        where
          pt ->> 'Type' = 'RESOURCE_CONTROL_POLICY'
          and pt ->> 'Status' = 'ENABLED'
      )
    union all
    select
      t.*,
      p.name,
      p.arn,
      p.type,
      p.aws_managed
    from
      targets as t
      join aws_organizations_policy_target as p on p.target_id = t.target_id and p.type = 'DECLARATIVE_POLICY_EC2'
    where
      exists (
        select
          1
        from
          aws_organizations_root as r,
          jsonb_array_elements(r.policy_types) as pt
        where
          pt ->> 'Type' = 'DECLARATIVE_POLICY_EC2'
          and pt ->> 'Status' = 'ENABLED'
      )
    union all
    select
      t.*,
      p.name,
      p.arn,
      p.type,
      p.aws_managed
    from
      targets as t
      join aws_organizations_policy_target as p on p.target_id = t.target_id and p.type = 'TAG_POLICY'
    where
      exists (
        select
          1
        from
          aws_organizations_root as r,
          jsonb_array_elements(r.policy_types) as pt
        where
          pt ->> 'Type' = 'TAG_POLICY'
          and pt ->> 'Status' = 'ENABLED'
      )
    union all
    select
      t.*,
      p.name,
      p.arn,
      p.type,
      p.aws_managed
    from
      targets as t
      join aws_organizations_policy_target as p on p.target_id = t.target_id and p.type = 'BACKUP_POLICY'
    where
      exists (
        select
          1
        from
          aws_organizations_root as r,
          jsonb_array_elements(r.policy_types) as pt
        where
          pt ->> 'Type' = 'BACKUP_POLICY'
          and pt ->> 'Status' = 'ENABLED'
      )
    union all
    select
      t.*,
      p.name,
      p.arn,
      p.type,
      p.aws_managed
    from
      targets as t
      join aws_organizations_policy_target as p on p.target_id = t.target_id and p.type = 'AISERVICES_OPT_OUT_POLICY'
    where
      exists (
        select
          1
        from
          aws_organizations_root as r,
          jsonb_array_elements(r.policy_types) as pt
        where
          pt ->> 'Type' = 'AISERVICES_OPT_OUT_POLICY'
          and pt ->> 'Status' = 'ENABLED'
      )
  EOQ
}

locals {
  # Policies attached directly to each target in $1, an array of root, organizational unit and
  # account ARNs.
  organizations_target_policies_sql = <<-EOQ
    with targets as (
      select
        id as target_id,
        arn as target_arn,
        name as target_name,
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
    ${local.organizations_policies_for_targets_sql}
  EOQ
}

locals {
  # Policies attached directly to every root, organizational unit and account.
  organizations_all_target_policies_sql = <<-EOQ
    with targets as (
      select
        id as target_id,
        arn as target_arn,
        name as target_name,
        'Root' as target_type,
        0 as depth
      from
        aws_organizations_root
      union all
      select
        id,
        arn,
        name,
        'Organizational Unit',
        nlevel(path) - 1
      from
        aws_organizations_organizational_unit
      union all
      select
        id,
        arn,
        name,
        'Account',
        99
      from
        aws_organizations_account
    )
    ${local.organizations_policies_for_targets_sql}
  EOQ
}

locals {
  # Reads the attachments returned by query.organizations_policy_attachments_for_targets ($1).
  organizations_policy_attachments_sql = <<-EOQ
    select
      *
    from
      jsonb_to_recordset($1::jsonb) as a(
        target_id text,
        target_arn text,
        target_name text,
        target_type text,
        depth int,
        policy_name text,
        policy_arn text,
        type text,
        aws_managed boolean
      )
  EOQ
}

# Policy attachments for a list of targets, as a single JSON array. Dashboards fetch this once in
# a with block and pass it to each panel, so each target's policies are only listed once.
query "organizations_policy_attachments_for_targets" {
  sql = <<-EOQ
    select
      coalesce(jsonb_agg(to_jsonb(a)), '[]'::jsonb) as attachments
    from
      (${local.organizations_target_policies_sql}) as a;
  EOQ
}

category "organizations_account" {
  title = "Organizations Account"
  color = local.management_governance_color
  href  = "/aws_insights.dashboard.organizations_account_detail?input.account_arn={{.properties.'ARN' | @uri}}"
  icon  = "cloud_circle"
}

category "organizations_aiservices_opt_out_policy" {
  title = "Organizations AI Services Opt-Out Policy"
  color = local.management_governance_color
  href  = "/aws_insights.dashboard.organizations_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "do_not_disturb_on"
}

category "organizations_backup_policy" {
  title = "Organizations Backup Policy"
  color = local.management_governance_color
  href  = "/aws_insights.dashboard.organizations_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "settings_backup_restore"
}

category "organizations_declarative_policy" {
  title = "Organizations Declarative Policy"
  color = local.iam_color
  href  = "/aws_insights.dashboard.organizations_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "gavel"
}

category "organizations_organizational_unit" {
  title = "Organizations Organizational Unit"
  color = local.management_governance_color
  href  = "/aws_insights.dashboard.organizations_organizational_unit_detail?input.organizational_unit_arn={{.properties.'ARN' | @uri}}"
  icon  = "folder"
}

category "organizations_resource_control_policy" {
  title = "Organizations Resource Control Policy"
  color = local.iam_color
  href  = "/aws_insights.dashboard.organizations_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "verified_user"
}

category "organizations_root" {
  title = "Organizations Root"
  color = local.management_governance_color
  href  = "/aws_insights.dashboard.organizations_root_detail?input.root_arn={{.properties.'ARN' | @uri}}"
  icon  = "account_tree"
}

category "organizations_service_control_policy" {
  title = "Organizations Service Control Policy"
  color = local.iam_color
  href  = "/aws_insights.dashboard.organizations_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "policy"
}

category "organizations_tag_policy" {
  title = "Organizations Tag Policy"
  color = local.management_governance_color
  href  = "/aws_insights.dashboard.organizations_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "sell"
}
