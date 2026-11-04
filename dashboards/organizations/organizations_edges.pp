edge "organizations_attached_target_to_policy" {
  title = "attaches"

  sql = <<-EOQ
    select
      target_arn as from_id,
      policy_arn as to_id
    from
      unnest($1::text[]) as target_arn,
      unnest($2::text[]) as policy_arn;
  EOQ

  param "organizations_target_arns" {}
  param "organizations_policy_arns" {}
}

edge "organizations_parent_to_account" {
  title = "account"

  sql = <<-EOQ
    with parents as (
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
    )
    select
      p.arn as from_id,
      a.arn as to_id
    from
      aws_organizations_account as a
      join parents as p on p.id = a.parent_id
    where
      a.arn = any($1);
  EOQ

  param "organizations_account_arns" {}
}

edge "organizations_parent_to_organizational_unit" {
  title = "organizational unit"

  sql = <<-EOQ
    with parents as (
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
    )
    select
      p.arn as from_id,
      ou.arn as to_id
    from
      aws_organizations_organizational_unit as ou
      join parents as p on p.id = ou.parent_id
    where
      ou.arn = any($1);
  EOQ

  param "organizations_organizational_unit_arns" {}
}

edge "organizations_target_to_policy" {
  title = "attaches"

  sql = <<-EOQ
    select
      target_arn as from_id,
      policy_arn as to_id
    from
      (${local.organizations_policy_attachments_sql}) as attachments
    where
      policy_arn = any($2);
  EOQ

  param "organizations_policy_attachments" {}
  param "organizations_policy_arns" {}
}
