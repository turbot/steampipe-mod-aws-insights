dashboard "organizations_organizational_unit_inventory_report" {

  title         = "AWS Organizations Organizational Unit Inventory Report"
  documentation = file("./dashboards/organizations/docs/organizations_organizational_unit_report_inventory.md")

  tags = merge(local.organizations_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.organizations_organizational_unit_count
      width = 2
    }

    card {
      query = query.organizations_organizational_unit_empty_count
      width = 2
    }

  }

  table {
    column "ARN" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.organizations_organizational_unit_detail.url_path}?input.organizational_unit_arn={{.ARN | @uri}}"
    }

    query = query.organizations_organizational_unit_inventory_table
  }

}

query "organizations_organizational_unit_empty_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Empty Organizational Units' as label,
      case count(*) when 0 then 'ok' else 'info' end as type
    from
      aws_organizations_organizational_unit as ou
    where
      not exists (select 1 from aws_organizations_account as a where a.parent_id = ou.id)
      and not exists (select 1 from aws_organizations_organizational_unit as child where child.parent_id = ou.id);
  EOQ
}

# Only the organizational units' own attachments are listed, so inherited policies aren't shown.
query "organizations_organizational_unit_inventory_table" {
  sql = <<-EOQ
    with targets as (
      select
        id as target_id,
        arn as target_arn,
        name as target_name,
        'Organizational Unit' as target_type,
        nlevel(path) - 1 as depth
      from
        aws_organizations_organizational_unit
    ),
    attached as (
      ${local.organizations_policies_for_targets_sql}
    ),
    paths as (
      select
        self.id,
        string_agg(ou.name, ' / ' order by nlevel(ou.path)) as ou_path
      from
        aws_organizations_organizational_unit as self
        join aws_organizations_organizational_unit as ou on ou.path @> self.path
      group by
        self.id
    )
    select
      ou.name as "Name",
      ou.id as "ID",
      'Root / ' || p.ou_path as "Path",
      (select count(*) from aws_organizations_organizational_unit as child where child.parent_id = ou.id) as "Child Organizational Units",
      (select count(*) from aws_organizations_account as a where a.parent_id = ou.id) as "Accounts",
      (select string_agg(policy_name, ', ' order by policy_name) from attached where target_id = ou.id and type = 'SERVICE_CONTROL_POLICY' and not aws_managed) as "Attached SCPs",
      (select string_agg(policy_name, ', ' order by policy_name) from attached where target_id = ou.id and type = 'RESOURCE_CONTROL_POLICY' and not aws_managed) as "Attached RCPs",
      (select string_agg(policy_name, ', ' order by policy_name) from attached where target_id = ou.id and type not in ('SERVICE_CONTROL_POLICY', 'RESOURCE_CONTROL_POLICY')) as "Other Attached Policies",
      ou.arn as "ARN"
    from
      aws_organizations_organizational_unit as ou
      join paths as p on p.id = ou.id
    order by
      "Path";
  EOQ
}
