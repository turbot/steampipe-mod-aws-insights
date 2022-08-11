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
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_dark.svg"))
    }

    category "aws_vpc" {
      href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.\"VPC ID\" | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/vpc_dark.svg"))
    }

    category "aws_vpc_security_group" {
      href = "${dashboard.aws_vpc_security_group_detail.url_path}?input.security_group_id={{.properties.\"Security Group ID\" | @uri}}"
      # icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/vpc_security_group.svg"))
    }

    # category "aws_vpc_subnet" {
    #   # href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.\"VPC ID\" | @uri}}"
    #   # icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/vpc_subnet_dark.svg"))
    # }

    category "uses" {
      color = "green"
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
  EOQ

  param "arn" {}
}


