dashboard "aws_rds_db_instance_detail" {

  title         = "AWS RDS DB Instance Detail"
  documentation = file("./dashboards/rds/docs/rds_db_instance_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "db_instance_arn" {
    title = "Select a DB Instance:"
    sql   = query.aws_rds_db_instance_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_rds_db_instance_engine_type
      args = {
        arn = self.input.db_instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_rds_db_instance_class
      args = {
        arn = self.input.db_instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_rds_db_instance_public
      args = {
        arn = self.input.db_instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_rds_db_instance_unencrypted
      args = {
        arn = self.input.db_instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_rds_db_instance_deletion_protection
      args = {
        arn = self.input.db_instance_arn.value
      }
    }

  }

  container {


    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_rds_db_instance_relationships_graph
      args = {
        arn = self.input.db_instance_arn.value
      }

      category "aws_rds_db_instance" {
        icon = local.aws_rds_db_instance_icon
      }

      category "aws_rds_db_cluster" {
        icon = local.aws_rds_db_cluster_icon
      }

      category "db_parameter_group" {
        ####icon = local.aws_rds_db_parameter_group_icon
      }

      category "db_subnet_group" {
        # icon = local.aws_vpc_icon
        icon = "cog"
      }

      category "aws_vpc" {
        # cyclic dependency prevents use of url_path, hardcode for now
        # href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.\"VPC ID\" | @uri}}"
        href = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{.properties.\"VPC ID\" | @uri}}"
        icon = "cloud" #local.aws_vpc_icon
      }

      category "aws_vpc_subnet" {
        # icon = local.aws_vpc_icon

        fold {
          threshold  = 3
          title      = "Subnets..."
          icon       = "collection"
        }
      }

      category "aws_vpc_security_group" {
        # cyclic dependency prevents use of url_path, hardcode for now
        # href = "${dashboard.aws_vpc_security_group_detail.url_path}?input.security_group_id={{.properties.\"Security Group ID\" | @uri}}"

        href = "/aws_insights.dashboard.aws_vpc_security_group_detail?input.security_group_id={{.properties.\"Security Group ID\" | @uri}}"
        # icon = local.aws_vpc_icon
        icon = "lock"
      }

      category "kms_key" {
        # cyclic dependency prevents use of url_path, hardcode for now
        # href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.ARN | @uri}}"

        href = "/aws_insights.dashboard.aws_kms_key_detail.url_path?input.key_arn={{.properties.ARN | @uri}}"
        icon = "key" #local.aws_kms_key_icon
      }

      category "uses" {
       // color = "green"
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
        query = query.aws_rds_db_instance_overview
        args = {
          arn = self.input.db_instance_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_rds_db_instance_tags
        args = {
          arn = self.input.db_instance_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "DB Parameter Groups"
        query = query.aws_rds_db_instance_parameter_groups
        args = {
          arn = self.input.db_instance_arn.value
        }
      }

      table {
        title = "Subnets"
        query = query.aws_rds_db_instance_subnets
        args = {
          arn = self.input.db_instance_arn.value
        }
      }

    }

    container {

      width = 12

      table {
        width = 6
        title = "Storage"
        query = query.aws_rds_db_instance_storage
        args = {
          arn = self.input.db_instance_arn.value
        }
      }

      table {
        width = 6
        title = "Logging"
        query = query.aws_rds_db_instance_logging
        args = {
          arn = self.input.db_instance_arn.value
        }
      }

    }

    container {

      width = 12

      table {
        width = 6
        title = "Security Groups"
        query = query.aws_rds_db_instance_security_groups
        args = {
          arn = self.input.db_instance_arn.value
        }
      }

      table {
        width = 6
        title = "DB Subnet Groups"
        query = query.aws_rds_db_instance_db_subnet_groups
        args = {
          arn = self.input.db_instance_arn.value
        }
      }

    }

  }

}

query "aws_rds_db_instance_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_rds_db_instance
    order by
      title;
  EOQ
}

query "aws_rds_db_instance_engine_type" {
  sql = <<-EOQ
    select
      'Engine Type' as label,
      engine as value
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_class" {
  sql = <<-EOQ
    select
      'Class' as label,
      class as value
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_public" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when not publicly_accessible then 'Disabled' else 'Enabled' end as value,
      case when not  publicly_accessible then 'ok' else 'alert' end as type
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_unencrypted" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when storage_encrypted then 'Enabled' else 'Disabled' end as value,
      case when storage_encrypted then 'ok' else 'alert' end as type
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_deletion_protection" {
  sql = <<-EOQ
    select
      'Deletion Protection' as label,
      case when deletion_protection then 'Enabled' else 'Disabled' end as value,
      case when deletion_protection then 'ok' else 'alert' end as type
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_parameter_groups" {
  sql = <<-EOQ
    select
      p ->> 'DBParameterGroupName' as "DB Parameter Group Name",
      p ->> 'ParameterApplyStatus' as "Parameter Apply Status"
    from
      aws_rds_db_instance,
      jsonb_array_elements(db_parameter_groups) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_subnets" {
  sql = <<-EOQ
    select
      p ->> 'SubnetIdentifier' as "Subnet Identifier",
      p -> 'SubnetAvailabilityZone' ->> 'Name' as "Subnet Availability Zone",
      p ->> 'SubnetStatus'  as "Subnet Status"
    from
      aws_rds_db_instance,
      jsonb_array_elements(subnets) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_storage" {
  sql = <<-EOQ
    select
      storage_type as "Storage Type",
      allocated_storage as "Allocated Storage",
      max_allocated_storage  as "Max Allocated Storage",
      storage_encrypted as "Storage Encrypted"
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_logging" {
  sql = <<-EOQ
    select
      enabled_cloudwatch_logs_exports as "Enabled CloudWatch Logs Exports",
      enhanced_monitoring_resource_arn as "Enhanced Monitoring Resource Arn"
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_security_groups" {
  sql = <<-EOQ
    select
      s ->> 'VpcSecurityGroupId' as "VPC Security Group ID",
      s ->> 'Status' as "Status"
    from
      aws_rds_db_instance,
      jsonb_array_elements(vpc_security_groups) as s
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_db_subnet_groups" {
  sql = <<-EOQ
    select
      db_subnet_group_name as "DB Subnet Group Name",
      db_subnet_group_arn as "DB Subnet Group ARN",
      db_subnet_group_status as "DB Subnet Group Status"
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_overview" {
  sql = <<-EOQ
    select
      db_instance_identifier as "DB Instance Identifier",
      case
        when vpc_id is not null and vpc_id != '' then vpc_id
        else 'N/A'
      end as "VPC ID",
      create_time as "Create Time",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_rds_db_instance,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}

query "aws_rds_db_instance_relationships_graph" {
  sql = <<-EOQ
    -- RDS DB instance (node)
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

    -- To RDS DB parameter groups (node)
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

    -- To RDS DB parameter groups (edge)
    union all
    select
      rdb.db_instance_identifier as from_id,
      db_parameter_group ->> 'DBParameterGroupName' as to_id,
      null as id,
      'parameter group' as title,
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
      aws_rds_db_instance rdb
      join aws_rds_db_subnet_group as rdsg on rdb.db_subnet_group_name = rdsg.name
      and rdb.region = rdsg.region and
      rdb.account_id = rdsg.account_id
    where
      rdb.arn = $1

    -- To RDS DB subnet group (edge)
    union all
    select
      rdb.db_instance_identifier as from_id,
      rdsg.name as to_id,
      null as id,
      'subnet group' as title,
      'uses' as category,
      jsonb_build_object(
        'Status', rdsg.status,
        'Account ID', rdsg.account_id,
        'Region', rdsg.region
      ) as properties
    from
      aws_rds_db_instance rdb
      join aws_rds_db_subnet_group as rdsg on rdb.db_subnet_group_name = rdsg.name
      and rdb.region = rdsg.region and
      rdb.account_id = rdsg.account_id
    where
      rdb.arn = $1

    -- To KMS Keys (node)
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
      join aws_kms_key as k on rdb.kms_key_id = k.arn
    where
      rdb.arn = $1

    -- To KMS keys (edge)
    union all
    select
      rdb.db_instance_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'DB Identifier', rdb.db_instance_identifier,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_rds_db_instance as rdb
      join aws_kms_key as k on rdb.kms_key_id = k.arn
    where
      rdb.arn = $1

    -- To VPC vpcs (node)
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

    -- To VPC subnets (node)
    union all
    select
      null as from_id,
      null as to_id,
      vs.subnet_id as id,
      vs.cidr_block::text as title,
            -- vs.title,
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
      join aws_vpc_subnet as vs on subnet ->> 'SubnetIdentifier' = vs.subnet_id
    where
      rdb.arn = $1

    -- To VPC subnets (edge)
    union all
    select
      rdb.db_subnet_group_name as from_id,
      vs.subnet_id as to_id,
      null as id,
      'subnet' as title,
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
      join aws_vpc_subnet as vs on subnet ->> 'SubnetIdentifier' = vs.subnet_id
    where
      rdb.arn = $1

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
      aws_rds_db_instance as di
      cross join jsonb_array_elements(di.vpc_security_groups) as dsg
      join aws_vpc_security_group as sg on sg.group_id = dsg ->> 'VpcSecurityGroupId'
    where
      di.arn = $1
      and di.vpc_id = sg.vpc_id

    -- To VPC security groups (edge)
    union all
    select
      di.db_instance_identifier as from_id,
      sg.group_id as to_id,
      null as id,
      'security group' as title,
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
      join aws_vpc_security_group as sg on sg.group_id = dsg ->> 'VpcSecurityGroupId'
    where
      di.arn = $1
      and di.vpc_id = sg.vpc_id

    -- To VPC subnets - vpcs (edge)
    union all
    select
      vs.subnet_id as from_id,
      vs.vpc_id as to_id,
      null as id,
      'vpc' as title,
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
      join aws_vpc_subnet as vs on subnet ->> 'SubnetIdentifier' = vs.subnet_id
    where
      rdb.arn = $1

    -- To VPC security groups - vpcs (edge)
    union all
    select
      sg.group_id as from_id,
      sg.vpc_id as to_id,
      null as id,
      'vpc' as title,
      'uses' as category,
      jsonb_build_object(
        'Security Group ID', sg.group_id,
        'VPC ID', sg.vpc_id,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      aws_rds_db_instance as di
      cross join jsonb_array_elements(di.vpc_security_groups) as dsg
      join aws_vpc_security_group as sg on sg.group_id = dsg ->> 'VpcSecurityGroupId'
    where
      di.arn = $1
      and di.vpc_id = sg.vpc_id


    -- From RDS DB cluster (node)
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
      join aws_rds_db_cluster as c on i.db_cluster_identifier = c.db_cluster_identifier
    where
      i.arn = $1

    -- From RDS DB cluster (edge)
    union all
    select
      c.db_cluster_identifier as from_id,
      i.db_instance_identifier as to_id,
      null as id,
      'instance' as title,
      'uses' as category,
      jsonb_build_object(
        'Cluster', c.title,
        'Instance', c.title,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_rds_db_instance as i
      join aws_rds_db_cluster as c on i.db_cluster_identifier = c.db_cluster_identifier
    where
      i.arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}
