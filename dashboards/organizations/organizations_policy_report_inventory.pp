dashboard "organizations_policy_inventory_report" {

  title         = "AWS Organizations Policy Inventory Report"
  documentation = file("./dashboards/organizations/docs/organizations_policy_report_inventory.md")

  tags = merge(local.organizations_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.organizations_service_control_policy_count
      width = 2
    }

    card {
      query = query.organizations_resource_control_policy_count
      width = 2
    }

    card {
      query = query.organizations_other_policy_count
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

    query = query.organizations_policy_inventory_table
  }

}

query "organizations_other_policy_count" {
  sql = <<-EOQ
    select
      count(*) as "Other Policies"
    from
      aws_organizations_policy
    where
      type in (
        'DECLARATIVE_POLICY_EC2',
        'TAG_POLICY',
        'BACKUP_POLICY',
        'AISERVICES_OPT_OUT_POLICY'
      )
      and not aws_managed;
  EOQ
}

query "organizations_policy_inventory_table" {
  sql = <<-EOQ
    with policies as (
      select
        distinct on (arn)
        name,
        id,
        arn,
        type,
        aws_managed,
        description
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
      name as "Name",
      id as "ID",
      type as "Type",
      aws_managed as "AWS Managed",
      description as "Description",
      arn as "ARN"
    from
      policies
    order by
      type,
      aws_managed,
      name;
  EOQ
}
