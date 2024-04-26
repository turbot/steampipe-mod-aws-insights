node "dax_cluster" {
  category = category.dax_cluster

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Cluster Name', cluster_name,
        'ARN', arn,
        'Account ID', account_id,
        'Name', title,
        'Region', region,
        'Status', status
      ) as properties
    from
      aws_dax_cluster
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "dax_cluster_arns" {}
}

node "dax_cluster_node" {
  category = category.dax_cluster_node

  sql = <<-EOQ
    select
      n ->> 'NodeId' as id,
      n ->> 'NodeId' as title,
      jsonb_build_object(
        'Status', n ->> 'NodeStatus',
        'Create Time', n ->> 'NodeCreateTime',
        'Account ID', account_id,
        'Availability Zone', n ->> 'AvailabilityZone',
        'Region', region,
        'Parameter Group Status', n ->> 'ParameterGroupStatus'
      ) as properties
    from
      aws_dax_cluster
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4),
      jsonb_array_elements(nodes) as n;
  EOQ

  param "dax_cluster_arns" {}
}

# Incorrect results when joining aws_dax_parameter_group and aws_dax_cluster with multiple join conditions for parameter_group, account_id and region
# Using inner query to compare the region
# https://github.com/turbot/steampipe-postgres-fdw/issues/271
node "dax_parameter_group" {
  category = category.dax_parameter_group
  sql      = <<-EOQ
    select
      p.parameter_group_name as id,
      p.title as title,
      jsonb_build_object(
        'Name', p.parameter_group_name,
        'Account ID', p.account_id,
        'Region', p.region
      ) as properties
    from
      aws_dax_parameter_group as p
      join aws_dax_cluster as c
        on c.parameter_group ->> 'ParameterGroupName' = p.parameter_group_name
        and p.account_id = c.account_id
    where
      c.arn = any($1)
      and p.region in (select region from aws_dax_cluster where arn = any($1))
  EOQ

  param "dax_cluster_arns" {}
}

node "dax_subnet_group" {
  category = category.dax_subnet_group
  sql      = <<-EOQ
    with dax_cluster as (
      select
        arn,
        subnet_group
      from
        aws_dax_cluster
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    ),  dax_subnet_group as (
      select
        subnet_group_name,
        title,
        vpc_id,
        region
      from
        aws_dax_subnet_group
    )
    select
      g.subnet_group_name as id,
      g.title as title,
      jsonb_build_object(
        'Name', g.subnet_group_name,
        'VPC ID', g.vpc_id,
        'Region', g.region
      ) as properties
    from
      dax_cluster as c,
      dax_subnet_group as g
    where
      g.subnet_group_name = c.subnet_group
  EOQ

  param "dax_cluster_arns" {}
}
