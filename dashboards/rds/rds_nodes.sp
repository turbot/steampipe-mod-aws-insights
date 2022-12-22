node "rds_db_cluster" {
  category = category.rds_db_cluster

  sql = <<-EOQ
    select
      arn as id,
      title,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Availability Zones', availability_zones::text,
        'Create Time', create_time,
        'Is Multi AZ', multi_az::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_cluster
    where
      arn = any($1);
  EOQ

  param "rds_db_cluster_arns" {}
}

node "rds_db_cluster_parameter_group" {
  category = category.rds_db_cluster_parameter_group

  sql = <<-EOQ
    select
      rg.arn as id,
      rg.name as title,
      jsonb_build_object(
        'ARN', rg.arn,
        'DB Parameter Group Family', rg.db_parameter_group_family,
        'Account ID', rg.account_id,
        'Region', rg.region
      ) as properties
    from
      aws_rds_db_cluster as rdc
      left join
        aws_rds_db_cluster_parameter_group as rg
        on rdc.db_cluster_parameter_group = rg.name
        and rdc.account_id = rg.account_id
        and rdc.region = rg.region
    where
      rdc.arn = any($1);
  EOQ

  param "rds_db_cluster_arns" {}
}

node "rds_db_cluster_snapshot" {
  category = category.rds_db_cluster_snapshot

  sql = <<-EOQ
    select
      arn as id,
      title,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Type', type,
        'DB Cluster Identifier', db_cluster_identifier,
        'Create Time', create_time,
        'Encrypted', storage_encrypted::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_cluster_snapshot
    where
      arn = any($1);
  EOQ

  param "rds_db_cluster_snapshot_arns" {}
}

node "rds_db_instance" {
  category = category.rds_db_instance

  sql = <<-EOQ
    select
      arn as id,
      title,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Public Access', publicly_accessible::text,
        'Availability Zone', availability_zone,
        'Create Time', create_time,
        'Is Multi AZ', multi_az::text,
        'Class', class,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_instance
    where
      arn = any($1);
  EOQ

  param "rds_db_instance_arns" {}
}

node "rds_db_parameter_group" {
  category = category.rds_db_parameter_group

  sql = <<-EOQ
    select
      rg.arn as id,
      rg.title as title,
      jsonb_build_object(
        'DB Parameter Group Apply Status', db_parameter_group ->> 'ParameterApplyStatus',
        'Account ID', rdb.account_id,
        'Region', rdb.region
      ) as properties
    from
      aws_rds_db_instance as rdb
      cross join jsonb_array_elements(db_parameter_groups) as db_parameter_group
      join aws_rds_db_parameter_group as rg
        on db_parameter_group ->> 'DBParameterGroupName' = rg.name
        and rdb.account_id = rg.account_id
        and rdb.region = rg.region
    where
      rdb.arn = any($1);
  EOQ

  param "rds_db_instance_arns" {}
}

node "rds_db_snapshot" {
  category = category.rds_db_snapshot

  sql = <<-EOQ
    select
      arn as id,
      title,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Availability Zone', availability_zone,
        'DB Instance Identifier', db_instance_identifier,
        'Create Time', create_time,
        'Encrypted', encrypted::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_snapshot
    where
      arn = any($1);
  EOQ

  param "rds_db_snapshot_arns" {}
}

node "rds_db_subnet_group" {
  category = category.rds_db_subnet_group

  sql = <<-EOQ
    select
      rdsg.arn as id,
      rdsg.title as title,
      jsonb_build_object(
        'Status', rdsg.status,
        'VPC ID', rdsg.vpc_id,
        'Account ID', rdsg.account_id,
        'Region', rdsg.region
      ) as properties
    from
      aws_rds_db_subnet_group as rdsg
    where
      rdsg.arn = any($1);
  EOQ

  param "rds_db_subnet_group_arns" {}
}
