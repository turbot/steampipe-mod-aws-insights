dashboard "aws_rds_db_instance_relationships" {

  title         = "AWS RDS DB Instance Relationships"
  documentation = file("./dashboards/rds/docs/rds_db_instance_relationships.md")

  tags = merge(local.rds_common_tags, {
    type = "Relationships"
  })

  input "db_instance_arn" {
    title = "Select a DB Instance:"
    query = query.aws_rds_db_instance_input
    width = 4
  }

  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_rds_db_instance_graph_from_instance
    args = {
      arn = self.input.db_instance_arn.value
    }
    category "aws_rds_db_instance" {
      href = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_dark.svg"))
    }

    category "aws_vpc" {
      href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.\"VPC ID\" | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_dark.svg"))
    }

    category "aws_vpc_security_group" {
      href = "${dashboard.aws_vpc_security_group_detail.url_path}?input.security_group_id={{.properties.\"Security Group ID\" | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
    }

    category "db_parameter_group" {

    }

    category "kms_key" {
      href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kms_key_dark.svg"))
    }

    category "aws_vpc_subnet" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
    }

    category "uses" {
      color = "green"
    }
  }

  graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_rds_db_instance_to_instance
    args = {
      arn = self.input.db_instance_arn.value
    }

    category "aws_rds_db_instance" {
      href = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_dark.svg"))
    }

    category "aws_rds_db_cluster" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_cluster_dark.svg"))
    }
  }
}

query "aws_rds_db_instance_graph_from_instance" {
  sql = <<-EOQ
    -- RDS DB INSTANCE NODE
    select
      null as from_id,
      null as to_id,
      db_instance_identifier as id,
      title,
      'aws_rds_db_instance' as category,
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
      arn = $1

    -- SUBNET NODE
    union all
    select
      null as from_id,
      null as to_id,
      vs.subnet_id as id,
      vs.title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'Subnet Id', vs.subnet_id,
        'VPC ID', vs.vpc_id,
        'Availability Zone', vs.availability_zone,
        'CIDR Block', vs.cidr_block,
        'Default for AZ', vs.default_for_az,
        'Map Public IP On Launch', vs.map_public_ip_on_launch,
        'Account ID', vs.account_id,
        'Region', vs.region
      ) as properties
    from
      aws_rds_db_instance as rdb
      cross join jsonb_array_elements(subnets) as subnet
      left join aws_vpc_subnet as vs on subnet ->> 'SubnetIdentifier' = vs.subnet_id and vs.availability_zone = rdb.availability_zone
    where
      vs.availability_zone is not null
      and rdb.arn = $1

    -- SECURITY GROUP NODE
    union all
    select
      null as from_id,
      null as to_id,
      sg.group_id as id,
      sg.title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'Security Group ID', sg.group_id,
        'VPC ID', sg.vpc_id,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      aws_rds_db_instance as di
      cross join jsonb_array_elements(di.vpc_security_groups) as dsg
      left join aws_vpc_security_group as sg on sg.group_id = dsg ->> 'VpcSecurityGroupId'
    where
      di.arn = $1
      and di.vpc_id = sg.vpc_id

    -- VPC NODE
    union all
    select
      null as from_id,
      null as to_id,
      v.vpc_id as id,
      v.title,
      'aws_vpc' as category,
      jsonb_build_object(
        'VPC ID', v.vpc_id,
        'ARN', v.arn,
        'CIDR Block', cidr_block,
        'Is Default', is_default::text,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_vpc as v,
      aws_rds_db_instance as di
    where
      di.arn = $1
      and v.vpc_id = di.vpc_id

    -- DB Parameter Group Node
    union all
    select
      null as from_id,
      null as to_id,
      db_parameter_group ->> 'DBParameterGroupName' as id,
      db_parameter_group ->> 'DBParameterGroupName' as title,
      'db_parameter_group' as category,
      jsonb_build_object(
        'DB Parameter Group Apply Status', db_parameter_group ->> 'ParameterApplyStatus',
        'Account ID', rdb.account_id,
        'Region', rdb.region
      ) as properties
    from
      aws_rds_db_instance as rdb,
      jsonb_array_elements(db_parameter_groups) as db_parameter_group
    where
      rdb.arn = $1

    -- KMS KEY Node
    union all
    select
      null as from_id,
      null as to_id,
      k.id as id,
      COALESCE(k.aliases #>> '{0,AliasName}', k.id) as title,
      'kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Rotation Enabled', k.key_rotation_enabled::text,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_rds_db_instance as rdb
      left join aws_kms_key as k on rdb.kms_key_id = k.arn
    where
      rdb.arn = $1

    -- SUBNET TO VPC -- EDGE
    union all
    select
      vs.subnet_id as from_id,
      vs.vpc_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Subnet Id', vs.subnet_id,
        'VPC ID', vs.vpc_id,
        'Subnet CIDR Block', vs.cidr_block,
        'Availability Zone', vs.availability_zone
      ) as properties
    from
      aws_rds_db_instance as rdb
      cross join jsonb_array_elements(subnets) as subnet
      left join aws_vpc_subnet as vs on subnet ->> 'SubnetIdentifier' = vs.subnet_id and vs.availability_zone = rdb.availability_zone
    where
      vs.availability_zone is not null
      and rdb.arn = $1

    -- DB INSTANCE TO SUBNET -- EDGE
    union all
    select
      rdb.db_instance_identifier as from_id,
      vs.subnet_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'DB Identifier', rdb.db_instance_identifier,
        'Subnet Id', vs.subnet_id,
        'Subnet CIDR Block', vs.cidr_block,
        'Account ID', vs.account_id,
        'Region', vs.region
      ) as properties
    from
      aws_rds_db_instance as rdb
      cross join jsonb_array_elements(subnets) as subnet
      left join aws_vpc_subnet as vs on subnet ->> 'SubnetIdentifier' = vs.subnet_id and vs.availability_zone = rdb.availability_zone
    where
      vs.availability_zone is not null
      and rdb.arn = $1

    -- DB TO SECURITY GROUP EDGE
    union all
    select
      di.db_instance_identifier as from_id,
      sg.group_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'DB Identifier', di.db_instance_identifier,
        'Security Group Name', sg.group_name,
        'Security Group ID', sg.group_id,
        'VPC ID', sg.vpc_id
      ) as properties
    from
      aws_rds_db_instance as di
      cross join jsonb_array_elements(di.vpc_security_groups) as dsg
      left join aws_vpc_security_group as sg on sg.group_id = dsg ->> 'VpcSecurityGroupId'
    where
      di.arn = $1
      and di.vpc_id = sg.vpc_id

    -- SECURITY GROUP TO VPC EDGE
    union all
    select
      sg.group_id as from_id,
      sg.vpc_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Security Group ID', sg.group_id,
        'VPC ID', sg.vpc_id
      ) as properties
    from
      aws_rds_db_instance as di
      cross join jsonb_array_elements(di.vpc_security_groups) as dsg
      left join aws_vpc_security_group as sg on sg.group_id = dsg ->> 'VpcSecurityGroupId'
    where
      di.arn = $1
      and di.vpc_id = sg.vpc_id

    -- DB Parameter Group EDGE
    union all
    select
      rdb.db_instance_identifier as from_id,
      db_parameter_group ->> 'DBParameterGroupName' as to_id,
      null as id,
      'uses_parameter_group' as title,
      'uses' as category,
      jsonb_build_object(
        'DB Parameter Group Apply Status', db_parameter_group ->> 'ParameterApplyStatus',
        'Account ID', rdb.account_id,
        'Region', rdb.region
      ) as properties
    from
      aws_rds_db_instance as rdb,
      jsonb_array_elements(db_parameter_groups) as db_parameter_group
    where
      rdb.arn = $1

    -- KMS KEY Edge
    union all
    select
      rdb.db_instance_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted_with' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'DB Identifier', rdb.db_instance_identifier,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_rds_db_instance as rdb
      left join aws_kms_key as k on rdb.kms_key_id = k.arn
    where
      rdb.arn = $1
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_to_instance" {
  sql = <<-EOQ
    -- RDS DB Instance NODE
    select
      null as from_id,
      null as to_id,
      db_instance_identifier as id,
      title,
      'aws_rds_db_instance' as category,
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
      arn = $1

    -- RDS DB Cluster NODE
    union all
    select
      null as from_id,
      null as to_id,
      c.db_cluster_identifier as id,
      c.title as title,
      'aws_rds_db_cluster' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Status', c.status,
        'Public Access', publicly_accessible::text,
        'Availability Zones', c.availability_zones::text,
        'Create Time', c.create_time,
        'Is Multi AZ', c.multi_az::text,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_rds_db_instance as i
      left join aws_rds_db_cluster as c on i.db_cluster_identifier = c.db_cluster_identifier
    where
      i.arn = $1

    -- Edge Cluster to DB
    union all
    select
      c.db_cluster_identifier as from_id,
      i.db_instance_identifier as to_id,
      null as id,
      'uses' as title,
      'uses' as title,
      jsonb_build_object(
        'Cluster', c.title,
        'Instance', c.title,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_rds_db_instance as i
      left join aws_rds_db_cluster as c on i.db_cluster_identifier = c.db_cluster_identifier
    where
      i.arn = $1
  EOQ

  param "arn" {}
}

