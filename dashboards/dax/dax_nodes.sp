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

node "dax_subnet_group" {
  category = category.dax_subnet_group
  sql      = <<-EOQ
    select
      subnet_group_name as id,
      title as title,
      jsonb_build_object(
        'Name', subnet_group_name,
        'VPC ID', vpc_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_dax_subnet_group
    where
      subnet_group_name = any($1);
  EOQ

  param "dax_subnet_group_names" {}
}

node "dax_parameter_group" {
  category = category.dax_parameter_group
  sql      = <<-EOQ
    select
      parameter_group_name as id,
      title as title,
      jsonb_build_object(
        'Name', parameter_group_name,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_dax_parameter_group
    where
      parameter_group_name = any($1);
  EOQ

  param "dax_parameter_group_names" {}
}