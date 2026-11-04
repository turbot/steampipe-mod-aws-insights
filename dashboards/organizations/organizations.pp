locals {
  organizations_common_tags = {
    service = "AWS/Organizations"
  }
}

locals {
  # Policies attached directly to each target in the "targets" CTE, from each policy's targets
  # (ListTargetsForPolicy), so there's one call per policy rather than one per target and type.
  organizations_policies_for_targets_sql = <<-EOQ
    select
      t.*,
      p.name as policy_name,
      p.arn as policy_arn,
      p.type,
      p.aws_managed
    from
      targets as t
      join (
        select
          distinct on (p.arn, pt ->> 'TargetId')
          p.name,
          p.arn,
          p.type,
          p.aws_managed,
          pt ->> 'TargetId' as target_id
        from
          aws_organizations_policy as p,
          jsonb_array_elements(p.targets) as pt
        where
          p.type in (
            'SERVICE_CONTROL_POLICY',
            'RESOURCE_CONTROL_POLICY',
            'DECLARATIVE_POLICY_EC2',
            'TAG_POLICY',
            'BACKUP_POLICY',
            'AISERVICES_OPT_OUT_POLICY'
          )
      ) as p on p.target_id = t.target_id
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
