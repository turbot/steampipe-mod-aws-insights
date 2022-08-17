dashboard "aws_rds_db_cluster_detail" {

  title         = "AWS RDS DB Cluster Detail"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "db_cluster_arn" {
    title = "Select a cluster:"
    query = query.aws_rds_db_cluster_input
    width = 4
  }

  container {

    card {
      query = query.aws_rds_db_cluster_unencrypted
      width = 2
      args = {
        arn = self.input.db_cluster_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_logging_disabled
      width = 2
      args = {
        arn = self.input.db_cluster_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_no_deletion_protection
      width = 2
      args = {
        arn = self.input.db_cluster_arn.value
      }
    }

    card {
      query = query.aws_rds_db_cluster_status
      width = 2
      args = {
        arn = self.input.db_cluster_arn.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_rds_db_cluster_relationships_graph
      args = {
        arn = self.input.db_cluster_arn.value
      }

      category "aws_rds_db_cluster" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_cluster_dark.svg"))
      }

      category "aws_rds_db_instance" {
        # cyclic dependency prevents use of url_path, hardcode for now
        # href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.\"VPC ID\" | @uri}}"

        href = "/aws_insights.dashboard.aws_rds_db_instance_detail.url_path?input.db_instance_arn={{.properties.ARN | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_dark.svg"))
      }

      category "aws_vpc_security_group" {
        # cyclic dependency prevents use of url_path, hardcode for now
        # href = "${dashboard.aws_vpc_security_group_detail.url_path}?input.security_group_id={{.properties.\"Security Group ID\" | @uri}}"

        href = "/aws_insights.dashboard.aws_vpc_security_group_detail?input.security_group_id={{.properties.\"Security Group ID\" | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
      }

      category "kms_key" {
        # cyclic dependency prevents use of url_path, hardcode for now
        # href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.ARN | @uri}}"

        href = "/aws_insights.dashboard.aws_kms_key_detail.url_path?input.key_arn={{.properties.ARN | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kms_key_dark.svg"))
      }

      category "db_cluster_parameter_group" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_parameter_group_dark.svg"))
      }

      category "db_subnet_group" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
      }

      category "aws_vpc_subnet" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
      }

      category "aws_vpc" {
        href = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{.properties.\"VPC ID\" | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_vpc_dark.svg"))
      }
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_rds_db_cluster_overview
        args = {
          arn = self.input.db_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_rds_db_cluster_tags
        args = {
          arn = self.input.db_cluster_arn.value
        }

      }
    }

  }
}

query "aws_rds_db_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_rds_db_cluster
    order by
      arn;
  EOQ
}

query "aws_rds_db_cluster_unencrypted" {
  sql = <<-EOQ
    select
      case when storage_encrypted then 'Enabled' else 'Disabled' end as value,
      'Encryption' as label,
      case when storage_encrypted then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_logging_disabled" {
  sql = <<-EOQ
    select
      case when enabled_cloudwatch_logs_exports is not null then 'Enabled' else 'Disabled' end as value,
      'Logging' as label,
      case when enabled_cloudwatch_logs_exports is not null then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_no_deletion_protection" {
  sql = <<-EOQ
    select
      case when deletion_protection then 'Enabled' else 'Disabled' end as value,
      'Deletion Protection' as label,
      case when deletion_protection then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_status" {
  sql = <<-EOQ
    select
      status as value,
      'Status' as label,
      case when status = 'available' then 'ok' else 'alert' end as type
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_overview" {
  sql = <<-EOQ
    select
      db_cluster_identifier as "Cluster Name",
      title as "Title",
      create_time as "Create Date",
      engine_version as "Engine Version",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_rds_db_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}


query "aws_rds_db_cluster_relationships_graph" {
  sql = <<-EOQ
    -- RDS cluster (node)
    select
      null as from_id,
      null as to_id,
      db_cluster_identifier as id,
      title,
      'aws_rds_db_cluster' as category,
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
      arn = $1

    -- To RDS cluster instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      i.db_instance_identifier as id,
      i.title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Status', i.status,
        'Public Access', i.publicly_accessible::text,
        'Availability Zone', i.availability_zone,
        'Create Time', i.create_time,
        'Is Multi AZ', i.multi_az::text,
        'Class', i.class,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_rds_db_cluster as c
      cross join jsonb_array_elements(members) as ci
      left join aws_rds_db_instance i on i.db_cluster_identifier = c.db_cluster_identifier and i.db_instance_identifier = ci ->> 'DBInstanceIdentifier'
    where
      c.arn = $1

    -- To RDS cluster instances (edge)
    union all
    select
      c.db_cluster_identifier as from_id,
      i.db_instance_identifier as to_id,
      null as id,
      'has instance' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Status', i.status,
        'Public Access', i.publicly_accessible::text,
        'Availability Zone', i.availability_zone,
        'Create Time', i.create_time,
        'Is Multi AZ', i.multi_az::text,
        'Class', i.class,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_rds_db_cluster as c
      cross join jsonb_array_elements(members) as ci
      left join aws_rds_db_instance i on i.db_cluster_identifier = c.db_cluster_identifier and i.db_instance_identifier = ci ->> 'DBInstanceIdentifier'
    where
      c.arn = $1

    -- To RDS DB cluster parameter groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      rg.name as id,
      rg.name as title,
      'db_cluster_parameter_group' as category,
      jsonb_build_object(
        'ARN', rg.arn,
        'DB Parameter Group Family', rg.db_parameter_group_family,
        'Account ID', rg.account_id,
        'Region', rg.region
      ) as properties
    from
      aws_rds_db_cluster as rdc
      left join aws_rds_db_cluster_parameter_group as rg on rdc.db_cluster_parameter_group = rg.name and rdc.account_id = rg.account_id and rdc.region = rg.region
    where
      rdc.arn = $1

    -- To RDS DB cluster parameter groups (edge)
    union all
    select
      rdc.db_cluster_identifier as from_id,
      rg.name as to_id,
      null as id,
      'uses parameter group' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', rg.arn,
        'DB Parameter Group Family', rg.db_parameter_group_family,
        'Account ID', rg.account_id,
        'Region', rg.region
      ) as properties
    from
      aws_rds_db_cluster as rdc
      left join aws_rds_db_cluster_parameter_group as rg on rdc.db_cluster_parameter_group = rg.name
      and rdc.account_id = rg.account_id
      and rdc.region = rg.region
    where
      rdc.arn = $1

    -- To RDS DB subnet group (node)
    union all
    select
      null as from_id,
      null as to_id,
      rdsg.name as id,
      rdsg.title as title,
      'db_subnet_group' as category,
      jsonb_build_object(
        'Status', rdsg.status,
        'VPC ID', rdsg.vpc_id,
        'Account ID', rdsg.account_id,
        'Region', rdsg.region
      ) as properties
    from
      aws_rds_db_cluster rdc
      left join aws_rds_db_subnet_group as rdsg on rdc.db_subnet_group = rdsg.name
      and rdc.region = rdsg.region and
      rdc.account_id = rdsg.account_id
    where
      rdc.arn = $1

    -- To RDS DB subnet group (edge)
    union all
    select
      rdc.db_cluster_identifier as from_id,
      rdsg.name as to_id,
      null as id,
      'uses subnet group' as title,
      'uses' as category,
      jsonb_build_object(
        'Status', rdsg.status,
        'VPC ID', rdsg.vpc_id,
        'Account ID', rdsg.account_id,
        'Region', rdsg.region
      ) as properties
    from
      aws_rds_db_cluster rdc
      left join aws_rds_db_subnet_group as rdsg on rdc.db_subnet_group = rdsg.name
      and rdc.region = rdsg.region and
      rdc.account_id = rdsg.account_id
    where
      rdc.arn = $1

    -- To KMS keys (node)
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
      aws_rds_db_cluster as c
      left join aws_kms_key as k on c.kms_key_id = k.arn
    where
      c.arn = $1

    -- To KMS keys (edge)
    union all
    select
      c.db_cluster_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Rotation Enabled', k.key_rotation_enabled::text,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_rds_db_cluster as c
      left join aws_kms_key as k on c.kms_key_id = k.arn
    where
      c.arn = $1

    -- To VPC security groups (node)
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
      aws_rds_db_cluster as c
      cross join jsonb_array_elements(c.vpc_security_groups) as csg
      left join aws_vpc_security_group as sg on sg.group_id = csg ->> 'VpcSecurityGroupId'
    where
      c.arn = $1

    -- To VPC security groups (edge)
    union all
    select
      c.db_cluster_identifier as from_id,
      sg.group_id as to_id,
      null as id,
      'uses security group' as title,
      'uses' as category,
      jsonb_build_object(
        'Security Group ID', sg.group_id,
        'VPC ID', sg.vpc_id,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      aws_rds_db_cluster as c
      cross join jsonb_array_elements(c.vpc_security_groups) as csg
      left join aws_vpc_security_group as sg on sg.group_id = csg ->> 'VpcSecurityGroupId'
    where
      c.arn = $1

    -- To VPC subnets (node)
    union all
    select
      null as from_id,
      null as to_id,
      avs.subnet_id as id,
      avs.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'CIDR Block', avs.cidr_block,
        'Availability Zone', avs.availability_zone,
        'State', avs.state,
        'VPC ID', avs.vpc_id,
        'Account ID', avs.account_id,
        'Region', avs.region
      ) as properties
    from
      aws_rds_db_cluster as rdc
      left join aws_rds_db_subnet_group as rdsg on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join jsonb_array_elements(rdsg.subnets) as vs
      left join aws_vpc_subnet as avs on avs.subnet_id = vs ->> 'SubnetIdentifier'
        and avs.account_id = rdsg.account_id
        and avs.region = rdsg.region
    where
      rdc.arn = $1

    -- To VPC subnets - subnet group (edge)
    union all
    select
      avs.subnet_id as from_id,
      rdc.db_subnet_group as to_id,
      null as id,
      'in subnet group' as title,
      'uses' as category,
      jsonb_build_object(
        'Subnet Name', avs.title,
        'Availability Zone', avs.availability_zone,
        'VPC ID', avs.vpc_id,
        'Account ID', avs.account_id,
        'Region', avs.region
      ) as properties
    from
      aws_rds_db_cluster as rdc
      left join aws_rds_db_subnet_group as rdsg on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join jsonb_array_elements(rdsg.subnets) as vs
      left join aws_vpc_subnet as avs on avs.subnet_id = vs ->> 'SubnetIdentifier'
        and avs.account_id = rdsg.account_id
        and avs.region = rdsg.region
    where
      rdc.arn = $1

    -- To VPC vpcs (node)
    union all
    select
      distinct
      null as from_id,
      null as to_id,
      v.vpc_id as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'VPC ID', v.vpc_id,
        'ARN', v.arn,
        'CIDR Block', v.cidr_block,
        'Is Default', v.is_default::text,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_rds_db_cluster as rdc
      join aws_rds_db_subnet_group as rdsg on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join jsonb_array_elements(rdsg.subnets) as vs
      join aws_vpc_subnet as avs on avs.subnet_id = vs ->> 'SubnetIdentifier'
        and avs.account_id = rdsg.account_id
        and avs.region = rdsg.region
      join aws_vpc as v on v.vpc_id = avs.vpc_id
        and v.region = avs.region
        and v.account_id = avs.account_id
    where
      rdc.arn = $1

    -- To VPC subnets (edge)
    union all
    select
      distinct
      avs.subnet_id as from_id,
      v.vpc_id as to_id,
      null as id,
      'in vpc' as title,
      'uses' as category,
      jsonb_build_object(
        'VPC ID', v.vpc_id,
        'Subnet Title', avs.title,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_rds_db_cluster as rdc
      join aws_rds_db_subnet_group as rdsg on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join jsonb_array_elements(rdsg.subnets) as vs
      join aws_vpc_subnet as avs on avs.subnet_id = vs ->> 'SubnetIdentifier'
        and avs.account_id = rdsg.account_id
        and avs.region = rdsg.region
      join aws_vpc as v on v.vpc_id = avs.vpc_id
        and v.region = avs.region
        and v.account_id = avs.account_id
    where
      rdc.arn = $1

    -- To VPC security group - vpcs (edge)
    union all
    select
      distinct
      sg.vpc_id as from_id,
      sg.group_id as to_id,
      null as id,
      'in vpc' as title,
      'uses' as category,
      jsonb_build_object(
        'Security Group ID', sg.group_id,
        'VPC ID', sg.vpc_id,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      aws_rds_db_cluster as c
      cross join jsonb_array_elements(c.vpc_security_groups) as csg
      join aws_vpc_security_group as sg on sg.group_id = csg ->> 'VpcSecurityGroupId'
    where
      c.arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}
