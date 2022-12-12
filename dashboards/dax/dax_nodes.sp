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
    where
      arn = any($1);
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
      aws_dax_cluster,
      jsonb_array_elements(nodes) as n
    where
      arn = any($1);
  EOQ

  param "dax_cluster_arns" {}
}

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
      aws_dax_parameter_group as p,
      aws_dax_cluster as c
    where
      c.parameter_group ->> 'ParameterGroupName' = p.parameter_group_name
      and c.arn = any($1);
  EOQ

  param "dax_cluster_arns" {}
}

node "dax_subnet_group" {
  category = category.dax_subnet_group
  sql      = <<-EOQ
    select
      g.subnet_group_name as id,
      g.title as title,
      jsonb_build_object(
        'Name', g.subnet_group_name,
        'VPC ID', g.vpc_id,
        'Account ID', g.account_id,
        'Region', g.region
      ) as properties
    from
      aws_dax_cluster as c,
      aws_dax_subnet_group as g
    where
      g.subnet_group_name = c.subnet_group
      and c.arn = any($1);
  EOQ

  param "dax_cluster_arns" {}
}
