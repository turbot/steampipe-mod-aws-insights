node "organizations_account" {
  category = category.organizations_account

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', id,
        'Email', email,
        'Status', status,
        'Joined Method', joined_method,
        'Joined Timestamp', joined_timestamp
      ) as properties
    from
      aws_organizations_account
    where
      arn = any($1);
  EOQ

  param "organizations_account_arns" {}
}

node "organizations_aiservices_opt_out_policy" {
  category = category.organizations_aiservices_opt_out_policy

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'ID', id,
        'Type', type,
        'AWS Managed', aws_managed::text,
        'Description', description
      ) as properties
    from
      aws_organizations_policy
    where
      type = 'AISERVICES_OPT_OUT_POLICY'
      and arn = any($1);
  EOQ

  param "organizations_policy_arns" {}
}

node "organizations_backup_policy" {
  category = category.organizations_backup_policy

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'ID', id,
        'Type', type,
        'AWS Managed', aws_managed::text,
        'Description', description
      ) as properties
    from
      aws_organizations_policy
    where
      type = 'BACKUP_POLICY'
      and arn = any($1);
  EOQ

  param "organizations_policy_arns" {}
}

node "organizations_declarative_policy" {
  category = category.organizations_declarative_policy

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'ID', id,
        'Type', type,
        'AWS Managed', aws_managed::text,
        'Description', description
      ) as properties
    from
      aws_organizations_policy
    where
      type = 'DECLARATIVE_POLICY_EC2'
      and arn = any($1);
  EOQ

  param "organizations_policy_arns" {}
}

node "organizations_organizational_unit" {
  category = category.organizations_organizational_unit

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'ID', id,
        'Parent ID', parent_id
      ) as properties
    from
      aws_organizations_organizational_unit
    where
      arn = any($1);
  EOQ

  param "organizations_organizational_unit_arns" {}
}

node "organizations_resource_control_policy" {
  category = category.organizations_resource_control_policy

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'ID', id,
        'Type', type,
        'AWS Managed', aws_managed::text,
        'Description', description
      ) as properties
    from
      aws_organizations_policy
    where
      type = 'RESOURCE_CONTROL_POLICY'
      and arn = any($1);
  EOQ

  param "organizations_policy_arns" {}
}

node "organizations_root" {
  category = category.organizations_root

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'ID', id,
        'Organization ID', split_part(arn, '/', 2),
        'Enabled Policy Types', (
          select
            string_agg(t ->> 'Type', ', ' order by t ->> 'Type')
          from
            jsonb_array_elements(policy_types) as t
          where
            t ->> 'Status' = 'ENABLED'
        )
      ) as properties
    from
      aws_organizations_root
    where
      arn = any($1);
  EOQ

  param "organizations_root_arns" {}
}

node "organizations_service_control_policy" {
  category = category.organizations_service_control_policy

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'ID', id,
        'Type', type,
        'AWS Managed', aws_managed::text,
        'Description', description
      ) as properties
    from
      aws_organizations_policy
    where
      type = 'SERVICE_CONTROL_POLICY'
      and arn = any($1);
  EOQ

  param "organizations_policy_arns" {}
}

node "organizations_tag_policy" {
  category = category.organizations_tag_policy

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'ID', id,
        'Type', type,
        'AWS Managed', aws_managed::text,
        'Description', description
      ) as properties
    from
      aws_organizations_policy
    where
      type = 'TAG_POLICY'
      and arn = any($1);
  EOQ

  param "organizations_policy_arns" {}
}
