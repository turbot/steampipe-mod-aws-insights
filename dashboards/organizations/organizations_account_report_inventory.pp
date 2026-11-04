dashboard "organizations_account_inventory_report" {

  title         = "AWS Organizations Account Inventory Report"
  documentation = file("./dashboards/organizations/docs/organizations_account_report_inventory.md")

  tags = merge(local.organizations_common_tags, {
    type     = "Report"
    category = "Inventory"
  })

  container {

    card {
      query = query.organizations_account_count
      width = 2
    }

    card {
      query = query.organizations_account_suspended_count
      width = 2
    }

  }

  table {
    column "ARN" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.organizations_account_detail.url_path}?input.account_arn={{.ARN | @uri}}"
    }

    query = query.organizations_account_inventory_table
  }

}

query "organizations_account_inventory_table" {
  sql = <<-EOQ
    with paths as (
      select
        a.id,
        string_agg(ou.name, ' / ' order by nlevel(ou.path)) as ou_path
      from
        aws_organizations_account as a
        join aws_organizations_organizational_unit as parent on parent.id = a.parent_id
        join aws_organizations_organizational_unit as ou on ou.path @> parent.path
      group by
        a.id
    )
    select
      a.name as "Name",
      a.id as "Account ID",
      a.status as "Status",
      case when a.id = a.account_id then 'Management' else 'Member' end as "Account Type",
      'Root' || coalesce(' / ' || p.ou_path, '') as "Path",
      a.email as "Email",
      a.joined_method as "Joined Method",
      a.joined_timestamp as "Joined Timestamp",
      a.tags as "Tags",
      a.arn as "ARN"
    from
      aws_organizations_account as a
      left join paths as p on p.id = a.id
    order by
      "Path",
      a.name;
  EOQ
}
