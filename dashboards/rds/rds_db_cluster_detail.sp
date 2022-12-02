dashboard "rds_db_cluster_detail" {

  title         = "AWS RDS DB Cluster Detail"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "db_cluster_arn" {
    title = "Select a cluster:"
    query = query.rds_db_cluster_input
    width = 4
  }

  container {

    card {
      query = query.rds_db_cluster_unencrypted
      width = 2
      args = {
        arn = self.input.db_cluster_arn.value
      }
    }

    card {
      query = query.rds_db_cluster_logging_disabled
      width = 2
      args = {
        arn = self.input.db_cluster_arn.value
      }
    }

    card {
      query = query.rds_db_cluster_no_deletion_protection
      width = 2
      args = {
        arn = self.input.db_cluster_arn.value
      }
    }

    card {
      query = query.rds_db_cluster_status
      width = 2
      args = {
        arn = self.input.db_cluster_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.rds_db_cluster,
        node.rds_db_cluster_to_iam_role_node,
        node.rds_db_cluster_to_sns_topic_node,
        node.rds_db_cluster_to_rds_db_cluster_snapshot_node,
        node.rds_db_cluster_to_rds_db_instance_node,
        node.rds_db_cluster_to_rds_db_cluster_parameter_group_node,
        node.rds_db_cluster_to_rds_db_subnet_group_node,
        node.rds_db_cluster_to_kms_key_node,
        node.rds_db_cluster_to_vpc_security_group_node,
        node.rds_db_cluster_vpc_subnet_to_rds_db_subnet_group_node,
        node.rds_db_cluster_vpc_subnet_to_vpc_node
      ]

      edges = [
        edge.rds_db_cluster_to_sns_topic_edge,
        edge.rds_db_cluster_to_iam_role_edge,
        edge.rds_db_cluster_to_rds_db_cluster_snapshot,
        edge.rds_db_cluster_to_rds_db_instance_edge,
        edge.rds_db_cluster_to_rds_db_cluster_parameter_group_edge,
        edge.rds_db_cluster_to_kms_key_edge,
        edge.rds_db_cluster_to_vpc_security_group_edge,
        edge.rds_db_cluster_vpc_subnet_to_rds_db_subnet_group_edge,
        edge.rds_db_cluster_vpc_subnet_to_vpc_edge,
        edge.rds_db_cluster_vpc_security_group_to_vpc_edge
      ]

      args = {
        rds_db_cluster_arns = [self.input.db_cluster_arn.value]
        arn                 = self.input.db_cluster_arn.value
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
        query = query.rds_db_cluster_overview
        args = {
          arn = self.input.db_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.rds_db_cluster_tags
        args = {
          arn = self.input.db_cluster_arn.value
        }

      }
    }

  }
}

query "rds_db_cluster_input" {
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

query "rds_db_cluster_unencrypted" {
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

query "rds_db_cluster_logging_disabled" {
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

query "rds_db_cluster_no_deletion_protection" {
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

query "rds_db_cluster_status" {
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

query "rds_db_cluster_overview" {
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

query "rds_db_cluster_tags" {
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

node "rds_db_cluster_to_rds_db_instance_node" {
  category = category.rds_db_instance

  sql = <<-EOQ
    select
      i.db_instance_identifier as id,
      i.title,
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
      join
        aws_rds_db_instance i
        on i.db_cluster_identifier = c.db_cluster_identifier
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

edge "rds_db_cluster_to_rds_db_instance_edge" {
  title = "instance"

  sql = <<-EOQ
    select
      c.arn as from_id,
      i.db_instance_identifier as to_id
    from
      aws_rds_db_cluster as c
      join
        aws_rds_db_instance i
        on i.db_cluster_identifier = c.db_cluster_identifier
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "rds_db_cluster_to_rds_db_cluster_parameter_group_node" {
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
      rdc.arn = $1;
  EOQ

  param "arn" {}
}

edge "rds_db_cluster_to_rds_db_cluster_parameter_group_edge" {
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
      rdc.arn = $1;
  EOQ

  param "arn" {}
}

node "rds_db_cluster_to_rds_db_subnet_group_node" {
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
      aws_rds_db_cluster rdc
      left join
        aws_rds_db_subnet_group as rdsg
        on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
    where
      rdc.arn = $1;
  EOQ

  param "arn" {}
}

node "rds_db_cluster_to_kms_key_node" {
  category = category.kms_key

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
      aws_rds_db_cluster as c
      left join
        aws_kms_key as k
        on c.kms_key_id = k.arn
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

edge "rds_db_cluster_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      c.arn as from_id,
      k.id as to_id
    from
      aws_rds_db_cluster as c
      left join
        aws_kms_key as k
        on c.kms_key_id = k.arn
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "rds_db_cluster_to_vpc_security_group_node" {
  category = category.vpc_security_group

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
      aws_rds_db_cluster as c
      cross join
        jsonb_array_elements(c.vpc_security_groups) as csg
      left join
        aws_vpc_security_group as sg
        on sg.group_id = csg ->> 'VpcSecurityGroupId'
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

edge "rds_db_cluster_to_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      c.arn as from_id,
      sg.group_id as to_id
    from
      aws_rds_db_cluster as c
      cross join
        jsonb_array_elements(c.vpc_security_groups) as csg
      left join
        aws_vpc_security_group as sg
        on sg.group_id = csg ->> 'VpcSecurityGroupId'
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "rds_db_cluster_vpc_subnet_to_rds_db_subnet_group_node" {
  category = category.vpc_subnet

  sql = <<-EOQ
    select
      avs.subnet_id as id,
      avs.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'Subnet ID', avs.subnet_id,
        'CIDR Block', avs.cidr_block,
        'Availability Zone', avs.availability_zone,
        'State', avs.state,
        'VPC ID', avs.vpc_id,
        'Account ID', avs.account_id,
        'Region', avs.region
      ) as properties
    from
      aws_rds_db_cluster as rdc
      left join
        aws_rds_db_subnet_group as rdsg
        on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join
        jsonb_array_elements(rdsg.subnets) as vs
      left join
        aws_vpc_subnet as avs
        on avs.subnet_id = vs ->> 'SubnetIdentifier'
        and avs.account_id = rdsg.account_id
        and avs.region = rdsg.region
    where
      rdc.arn = $1;
  EOQ

  param "arn" {}
}

edge "rds_db_cluster_vpc_subnet_to_rds_db_subnet_group_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      rdsg.arn as from_id,
      avs.subnet_id as to_id
    from
      aws_rds_db_cluster as rdc
      left join
        aws_rds_db_subnet_group as rdsg
        on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join
        jsonb_array_elements(rdsg.subnets) as vs
      left join
        aws_vpc_subnet as avs
        on avs.subnet_id = vs ->> 'SubnetIdentifier'
        and avs.account_id = rdsg.account_id
        and avs.region = rdsg.region
    where
      rdc.arn = $1;
  EOQ

  param "arn" {}
}

node "rds_db_cluster_vpc_subnet_to_vpc_node" {
  category = category.vpc_vpc

  sql = <<-EOQ
    select
      distinct
      v.vpc_id as id,
      v.title as title,
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
      join
        aws_rds_db_subnet_group as rdsg
        on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join
        jsonb_array_elements(rdsg.subnets) as vs
      join
        aws_vpc_subnet as avs
        on avs.subnet_id = vs ->> 'SubnetIdentifier'
        and avs.account_id = rdsg.account_id
        and avs.region = rdsg.region
      join
        aws_vpc as v
        on v.vpc_id = avs.vpc_id
        and v.region = avs.region
        and v.account_id = avs.account_id
    where
      rdc.arn = $1;
  EOQ

  param "arn" {}
}

edge "rds_db_cluster_vpc_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      distinct
      avs.subnet_id as from_id,
      v.vpc_id as to_id
    from
      aws_rds_db_cluster as rdc
      join
        aws_rds_db_subnet_group as rdsg
        on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join
        jsonb_array_elements(rdsg.subnets) as vs
      join
        aws_vpc_subnet as avs
        on avs.subnet_id = vs ->> 'SubnetIdentifier'
        and avs.account_id = rdsg.account_id
        and avs.region = rdsg.region
      join
        aws_vpc as v
        on v.vpc_id = avs.vpc_id
        and v.region = avs.region
        and v.account_id = avs.account_id
    where
      rdc.arn = $1;
  EOQ

  param "arn" {}
}

edge "rds_db_cluster_vpc_security_group_to_vpc_edge" {
  title = "subnet group"

  sql = <<-EOQ
    select
      distinct
      sg.group_id as from_id,
      rdsg.arn as to_id
    from
      aws_rds_db_cluster as c
      cross join
        jsonb_array_elements(c.vpc_security_groups) as csg
      join
        aws_vpc_security_group as sg
        on sg.group_id = csg ->> 'VpcSecurityGroupId'
      join
        aws_rds_db_subnet_group as rdsg
        on c.db_subnet_group = rdsg.name
        and c.region = rdsg.region
        and c.account_id = rdsg.account_id
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "rds_db_cluster_to_rds_db_cluster_snapshot_node" {
  category = category.rds_db_cluster_snapshot

  sql = <<-EOQ
    select
      s.db_cluster_snapshot_identifier as id,
      s.title as title,
      jsonb_build_object(
        'ARN', s.arn,
        'Status', s.status,
        'Type', s.type,
        'Create Time', s.create_time,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_rds_db_cluster as c
      join
        aws_rds_db_cluster_snapshot as s
        on s.db_cluster_identifier = c.db_cluster_identifier
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

edge "rds_db_cluster_to_rds_db_cluster_snapshot" {
  title = "snapshot"

  sql = <<-EOQ
    select
      rds_db_cluster_arn as from_id,
      rds_db_cluster_snapshot_arn as to_id
    from
     unnest($1::text[]) as rds_db_cluster_arn,
      unnest($2::text[]) as rds_db_cluster_snapshot_arn
  EOQ

  param "rds_db_cluster_arns" {}
  param "rds_db_cluster_snapshot_arns" {}
}

node "rds_db_cluster_to_sns_topic_node" {
  category = category.sns_topic

  sql = <<-EOQ
    select
      s.sns_topic_arn as id,
      split_part(s.sns_topic_arn, ':', -1) as title,
      jsonb_build_object(
        'ARN', s.sns_topic_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_rds_db_event_subscription as s,
      jsonb_array_elements_text(source_ids_list) as ids
      join aws_rds_db_cluster as c
      on ids = c.db_cluster_identifier
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

edge "rds_db_cluster_to_sns_topic_edge" {
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
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "rds_db_cluster_to_iam_role_node" {
  category = category.iam_role

  sql = <<-EOQ
    select
      r.role_id as id,
      r.name as title,
      jsonb_build_object(
        'ARN', r.arn,
        'Create Date', r.create_date,
        'Max Session Duration', r.max_session_duration,
        'Account ID', r.account_id
      ) as properties
    from
      aws_rds_db_cluster as c
      cross join jsonb_array_elements(associated_roles) as roles
      join aws_iam_role as r
      on roles ->> 'RoleArn' = r.arn
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

edge "rds_db_cluster_to_iam_role_edge" {
  title = "assumes"

  sql = <<-EOQ
    select
      c.arn as from_id,
      r.role_id as to_id
    from
      aws_rds_db_cluster as c
      cross join jsonb_array_elements(associated_roles) as roles
      join aws_iam_role as r
      on roles ->> 'RoleArn' = r.arn
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}
