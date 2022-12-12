edge "rds_db_cluster_snapshot_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_rds_db_cluster_snapshot
    where
      kms_key_id is not null
      and arn = any($1);
  EOQ

  param "rds_db_cluster_snapshot_arns" {}
}

edge "rds_db_cluster_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      arn as from_id,
      roles ->> 'RoleArn' as to_id
    from
      aws_rds_db_cluster
      cross join jsonb_array_elements(associated_roles) as roles
    where
      arn = any($1);
  EOQ

  param "rds_db_cluster_arns" {}
}

edge "rds_db_cluster_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_rds_db_cluster
    where
      arn = any($1);
  EOQ

  param "rds_db_cluster_arns" {}
}

edge "rds_db_cluster_to_rds_db_cluster_parameter_group" {
  title = "parameter group"

  sql = <<-EOQ
    select
      rdc.arn as from_id,
      rg.arn as to_id
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

edge "rds_db_cluster_to_rds_db_cluster_snapshot" {
  title = "snapshot"

  sql = <<-EOQ
    select
      c.arn as from_id,
      s.arn as to_id
    from
      aws_rds_db_cluster as c
      join aws_rds_db_cluster_snapshot as s
      on s.db_cluster_identifier = c.db_cluster_identifier
    where
      c.arn = any($1);
  EOQ

  param "rds_db_cluster_arns" {}
}

edge "rds_db_cluster_to_rds_db_instance" {
  title = "instance"

  sql = <<-EOQ
    select
      c.arn as from_id,
      i.arn as to_id
    from
      aws_rds_db_instance as i
      join
        aws_rds_db_cluster as c
        on i.db_cluster_identifier = c.db_cluster_identifier
    where
      c.arn = any($1);
  EOQ

  param "rds_db_cluster_arns" {}
}

edge "rds_db_cluster_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      c.arn as from_id,
      s.sns_topic_arn as to_id
    from
      aws_rds_db_event_subscription as s,
      jsonb_array_elements_text(source_ids_list) as ids
      join aws_rds_db_cluster as c
      on ids = c.db_cluster_identifier
    where
      c.arn = any($1);
  EOQ

  param "rds_db_cluster_arns" {}
}

edge "rds_db_cluster_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      c.arn as from_id,
      csg ->> 'VpcSecurityGroupId' as to_id
    from
      aws_rds_db_cluster as c
      cross join
        jsonb_array_elements(c.vpc_security_groups) as csg
    where
      c.arn = any($1);
  EOQ

  param "rds_db_cluster_arns" {}
}

edge "rds_db_instance_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_rds_db_instance
    where
      arn = any($1);
  EOQ

  param "rds_db_instance_arns" {}
}

edge "rds_db_instance_to_rds_db_parameter_group" {
  title = "parameter group"

  sql = <<-EOQ
    select
      rdb.arn as from_id,
      rg.arn as to_id
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

edge "rds_db_instance_to_rds_db_snapshot" {
  title = "snapshot"

  sql = <<-EOQ
    select
      i.arn as from_id,
      s.arn as to_id
    from
      aws_rds_db_instance as i
      join aws_rds_db_snapshot as s
        on s.dbi_resource_id = i.resource_id
    where
      s.arn = $1;
  EOQ

  param "rds_db_instance_arns" {}
}

edge "rds_db_instance_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      i.arn as from_id,
      s.sns_topic_arn as to_id
    from
      aws_rds_db_event_subscription as s,
      jsonb_array_elements_text(source_ids_list) as ids
      join aws_rds_db_instance as i
      on ids = i.db_instance_identifier
    where
      i.arn = any($1);
  EOQ

  param "rds_db_instance_arns" {}
}

edge "rds_db_instance_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      arn as from_id,
      dsg ->> 'VpcSecurityGroupId' as to_id
    from
      aws_rds_db_instance as di,
      jsonb_array_elements(di.vpc_security_groups) as dsg
    where
      arn = any($1);
  EOQ

  param "rds_db_instance_arns" {}
}

// edge "rds_db_instance_vpc_subnet_to_vpc" {
//   title = "vpc"

//   sql = <<-EOQ
//     select
//       subnet ->> 'SubnetIdentifier' as from_id,
//       vpc_id as to_id
//     from
//       aws_rds_db_instance as rdb,
//       jsonb_array_elements(subnets) as subnet
//     where
//       arn = any($1);
//   EOQ

//   param "rds_db_instance_arns" {}
// }

edge "rds_db_snapshot_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_rds_db_snapshot
    where
      kms_key_id is not null
      and arn = any($1);
  EOQ

  param "rds_db_snapshot_arns" {}
}

edge "rds_db_subnet_group_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      rdsg.arn as from_id,
      vs ->> 'SubnetIdentifier' as to_id
    from
      aws_rds_db_cluster as rdc
      left join
        aws_rds_db_subnet_group as rdsg
        on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join
        jsonb_array_elements(rdsg.subnets) as vs
    where
      rdc.arn = any($1);
  EOQ

  param "rds_db_cluster_arns" {}
}
