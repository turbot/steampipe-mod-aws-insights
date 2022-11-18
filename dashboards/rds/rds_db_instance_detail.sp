dashboard "aws_rds_db_instance_detail" {

  title         = "AWS RDS DB Instance Detail"
  documentation = file("./dashboards/rds/docs/rds_db_instance_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "db_instance_arn" {
    title = "Select a DB Instance:"
    query = query.aws_rds_db_instance_input
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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"


      nodes = [
        node.aws_rds_db_instance_node,
        node.aws_rds_db_instance_to_rds_db_parameter_group_node,
        node.aws_rds_db_instance_to_rds_db_subnet_group_node,
        node.aws_rds_db_instance_to_kms_key_node,
        node.aws_rds_db_instance_to_vpc_node,
        node.aws_rds_db_instance_rds_db_subnet_group_to_vpc_subnet_node,
        node.aws_rds_db_instance_to_vpc_security_group_node,
        node.aws_rds_db_instance_from_rds_db_cluster_node
      ]

      edges = [
        edge.aws_rds_db_instance_to_rds_db_parameter_group_edge,
        edge.aws_rds_db_instance_to_kms_key_edge,
        edge.aws_rds_db_instance_rds_db_subnet_group_to_vpc_subnet_edge,
        edge.aws_rds_db_instance_to_vpc_security_group_edge,
        edge.aws_rds_db_instance_vpc_subnet_to_vpc_edge,
        edge.aws_rds_db_instance_vpc_security_group_to_vpc_edge,
        edge.aws_rds_db_instance_from_rds_db_cluster_edge
      ]

      args = {
        arn = self.input.db_instance_arn.value
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

node "aws_rds_db_instance_node" {
  category = category.aws_rds_db_instance

  sql = <<-EOQ
    select
      db_instance_identifier as id,
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
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_rds_db_instance_to_rds_db_parameter_group_node" {
  category = category.aws_rds_db_parameter_group

  sql = <<-EOQ
    select
      db_parameter_group ->> 'DBParameterGroupName' as id,
      db_parameter_group ->> 'DBParameterGroupName' as title,
      jsonb_build_object(
        'DB Parameter Group Apply Status', db_parameter_group ->> 'ParameterApplyStatus',
        'Account ID', rdb.account_id,
        'Region', rdb.region
      ) as properties
    from
      aws_rds_db_instance as rdb,
      jsonb_array_elements(db_parameter_groups) as db_parameter_group
    where
      rdb.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_rds_db_instance_to_rds_db_parameter_group_edge" {
  title = "parameter group"

  sql = <<-EOQ
    select
      rdb.db_instance_identifier as from_id,
      db_parameter_group ->> 'DBParameterGroupName' as to_id
    from
      aws_rds_db_instance as rdb,
      jsonb_array_elements(db_parameter_groups) as db_parameter_group
    where
      rdb.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_rds_db_instance_to_rds_db_subnet_group_node" {
  category = category.aws_rds_db_subnet_group

  sql = <<-EOQ
    select
      rdsg.name as id,
      rdsg.title as title,
      jsonb_build_object(
        'Status', rdsg.status,
        'VPC ID', rdsg.vpc_id,
        'Account ID', rdsg.account_id,
        'Region', rdsg.region
      ) as properties
    from
      aws_rds_db_instance rdb
      join
        aws_rds_db_subnet_group as rdsg
        on rdb.db_subnet_group_name = rdsg.name
        and rdb.region = rdsg.region
        and rdb.account_id = rdsg.account_id
    where
      rdb.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_rds_db_instance_to_kms_key_node" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      k.id as id,
      k.title as title,
      jsonb_build_object(
        'ARN', k.arn,
        'Rotation Enabled', k.key_rotation_enabled::text,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_rds_db_instance as rdb
      join
        aws_kms_key as k
        on rdb.kms_key_id = k.arn
    where
      rdb.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_rds_db_instance_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      rdb.db_instance_identifier as from_id,
      k.id as to_id
    from
      aws_rds_db_instance as rdb
      join
        aws_kms_key as k
        on rdb.kms_key_id = k.arn
    where
      rdb.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_rds_db_instance_to_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      v.vpc_id as id,
      v.title,
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
      and v.vpc_id = di.vpc_id;
  EOQ

  param "arn" {}
}

node "aws_rds_db_instance_rds_db_subnet_group_to_vpc_subnet_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      vs.subnet_id as id,
      vs.title,
      jsonb_build_object(
        'Subnet ID', vs.subnet_id,
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
      cross join
        jsonb_array_elements(subnets) as subnet
      join
        aws_vpc_subnet as vs
          on subnet ->> 'SubnetIdentifier' = vs.subnet_id
    where
      rdb.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_rds_db_instance_rds_db_subnet_group_to_vpc_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      rdb.db_subnet_group_name as from_id,
      vs.subnet_id as to_id
    from
      aws_rds_db_instance as rdb
      cross join
        jsonb_array_elements(subnets) as subnet
      join
        aws_vpc_subnet as vs
        on subnet ->> 'SubnetIdentifier' = vs.subnet_id
    where
      rdb.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_rds_db_instance_to_vpc_security_group_node" {
  category = category.aws_vpc_security_group

  sql = <<-EOQ
    select
      sg.group_id as id,
      sg.title,
      jsonb_build_object(
        'Group ID', sg.group_id,
        'VPC ID', sg.vpc_id,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      aws_rds_db_instance as di
      cross join
        jsonb_array_elements(di.vpc_security_groups) as dsg
      join
        aws_vpc_security_group as sg
        on sg.group_id = dsg ->> 'VpcSecurityGroupId'
    where
      di.arn = $1
      and di.vpc_id = sg.vpc_id;
  EOQ

  param "arn" {}
}

edge "aws_rds_db_instance_to_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      di.db_instance_identifier as from_id,
      sg.group_id as to_id
    from
      aws_rds_db_instance as di
      cross join
        jsonb_array_elements(di.vpc_security_groups) as dsg
      join
        aws_vpc_security_group as sg
        on sg.group_id = dsg ->> 'VpcSecurityGroupId'
    where
      di.arn = $1
      and di.vpc_id = sg.vpc_id;
  EOQ

  param "arn" {}
}

edge "aws_rds_db_instance_vpc_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      vs.subnet_id as from_id,
      vs.vpc_id as to_id
    from
      aws_rds_db_instance as rdb
      cross join
        jsonb_array_elements(subnets) as subnet
      join
        aws_vpc_subnet as vs
        on subnet ->> 'SubnetIdentifier' = vs.subnet_id
    where
      rdb.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_rds_db_instance_vpc_security_group_to_vpc_edge" {
  title = "subnet group"

  sql = <<-EOQ
    select
      sg.group_id as from_id,
      rdsg.name as to_id
    from
      aws_rds_db_instance as di
      cross join
        jsonb_array_elements(di.vpc_security_groups) as dsg
      join
        aws_vpc_security_group as sg
        on sg.group_id = dsg ->> 'VpcSecurityGroupId'
      join
        aws_rds_db_subnet_group as rdsg
        on di.db_subnet_group_name = rdsg.name
        and di.region = rdsg.region
        and di.account_id = rdsg.account_id
    where
      di.arn = $1
      and di.vpc_id = sg.vpc_id;
  EOQ

  param "arn" {}
}

node "aws_rds_db_instance_from_rds_db_cluster_node" {
  category = category.aws_rds_db_cluster

  sql = <<-EOQ
    select
      c.db_cluster_identifier as id,
      c.title as title,
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
      join
        aws_rds_db_cluster as c
        on i.db_cluster_identifier = c.db_cluster_identifier
    where
      i.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_rds_db_instance_from_rds_db_cluster_edge" {
  title = "instance"

  sql = <<-EOQ
    select
      c.db_cluster_identifier as from_id,
      i.db_instance_identifier as to_id
    from
      aws_rds_db_instance as i
      join
        aws_rds_db_cluster as c
        on i.db_cluster_identifier = c.db_cluster_identifier
    where
      i.arn = $1;
  EOQ

  param "arn" {}
}
