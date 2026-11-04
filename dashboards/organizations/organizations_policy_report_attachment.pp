dashboard "organizations_policy_attachment_report" {

  title         = "AWS Organizations Policy Attachment Report"
  documentation = file("./dashboards/organizations/docs/organizations_policy_report_attachment.md")

  tags = merge(local.organizations_common_tags, {
    type     = "Report"
    category = "Attachment"
  })

  container {

    card {
      query = query.organizations_custom_policy_count
      width = 2
    }

    card {
      query = query.organizations_policy_unattached_count
      width = 2
    }

  }

  table {
    column "ARN" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.organizations_policy_detail.url_path}?input.policy_arn={{.ARN | @uri}}"
    }

    query = query.organizations_policy_attachment_table
  }

}

query "organizations_custom_policy_count" {
  sql = <<-EOQ
    select
      count(*) as "Customer Managed Policies"
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
      and not aws_managed;
  EOQ
}

# Customer managed policies only, unattached first.
query "organizations_policy_attachment_table" {
  sql = <<-EOQ
    with attached as (
      ${local.organizations_all_target_policies_sql}
    ),
    policies as (
      select
        distinct on (arn)
        name,
        arn,
        type
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
    )
    select
      p.name as "Name",
      p.type as "Type",
      case when count(a.target_arn) = 0 then 'Unattached' else 'Attached' end as "Status",
      count(a.target_arn) as "Attached Targets",
      string_agg(a.target_name, ', ' order by a.depth, a.target_name) as "Attached To",
      p.arn as "ARN"
    from
      policies as p
      left join attached as a on a.policy_arn = p.arn
    group by
      p.name,
      p.type,
      p.arn
    order by
      count(a.target_arn),
      p.type,
      p.name;
  EOQ
}
