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
      direction = "top-down"

      with "snapshots" {
        sql = <<-EOQ
          select
            s.arn as snapshot_arn
          from
            aws_rds_db_instance as i
            join aws_rds_db_snapshot as s
              on s.dbi_resource_id = i.resource_id
          where
            i.arn = $1;
        EOQ

        args = [self.input.db_instance_arn.value]
      }

      with "topics" {
        sql = <<-EOQ
          select
            s.sns_topic_arn
          from
            aws_rds_db_event_subscription as s,
            jsonb_array_elements_text(source_ids_list) as ids
            join aws_rds_db_instance as i
            on ids = i.db_instance_identifier
          where
            i.arn = $1;
        EOQ

        args = [self.input.db_instance_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            rdb.kms_key_id as key_arn
          from
            aws_rds_db_instance rdb
          where
            rdb.arn = $1;
        EOQ

        args = [self.input.db_instance_arn.value]
      }

      with "vpcs" {
        sql = <<-EOQ
          select
            vpc_id
          from
            aws_rds_db_instance as di
          where
            di.arn = $1;
        EOQ

        args = [self.input.db_instance_arn.value]
      }

      with "vpc_subnets" {
        sql = <<-EOQ
          select
            subnet ->> 'SubnetIdentifier' as subnet_id
          from
            aws_rds_db_instance as rdb,
            jsonb_array_elements(subnets) as subnet
          where
            rdb.arn = $1;
        EOQ

        args = [self.input.db_instance_arn.value]
      }

      with "vpc_security_groups" {
        sql = <<-EOQ
          select
            dsg ->> 'VpcSecurityGroupId' as security_group_id
          from
            aws_rds_db_instance as di,
            jsonb_array_elements(di.vpc_security_groups) as dsg
          where
            di.arn = $1;
        EOQ

        args = [self.input.db_instance_arn.value]
      }

      with "db_clusters" {
        sql = <<-EOQ
          select
            c.arn as cluster_arn
          from
            aws_rds_db_instance as i
            join
              aws_rds_db_cluster as c
              on i.db_cluster_identifier = c.db_cluster_identifier
          where
            i.arn = $1;
        EOQ

        args = [self.input.db_instance_arn.value]
      }

      nodes = [
        node.aws_rds_db_instance_nodes,
        node.aws_rds_db_snapshot_nodes,
        node.aws_sns_topic_nodes,
        node.aws_rds_db_instance_to_rds_db_parameter_group_node,
        node.aws_rds_db_instance_to_rds_db_subnet_group_node,
        node.aws_kms_key_nodes,
        node.vpc_vpc,
        node.vpc_subnet,
        node.vpc_security_group,
        node.aws_rds_db_cluster_nodes
      ]

      edges = [
        edge.aws_rds_db_instance_to_rds_db_snapshot_edges,
        edge.aws_rds_db_instance_to_sns_topic_edge,
        edge.aws_rds_db_instance_to_rds_db_parameter_group_edge,
        edge.aws_rds_db_instance_to_kms_key_edge,
        edge.aws_rds_db_instance_rds_db_subnet_group_to_vpc_subnet_edge,
        edge.aws_rds_db_instance_to_vpc_security_group_edge,
        edge.aws_rds_db_instance_vpc_subnet_to_vpc_edge,
        edge.aws_rds_db_instance_vpc_security_group_to_vpc_edge,
        edge.aws_rds_db_instance_from_rds_db_cluster_edge
      ]

      args = {
        rds_db_instance_arns = [self.input.db_instance_arn.value]
        rds_db_snapshot_arns = with.snapshots.rows[*].snapshot_arn
        topic_arns           = with.topics.rows[*].sns_topic_arn
        key_arns             = with.kms_keys.rows[*].key_arn
        vpc_ids              = with.vpcs.rows[*].vpc_id
        subnet_ids           = with.vpc_subnets.rows[*].subnet_id
        security_group_ids   = with.vpc_security_groups.rows[*].security_group_id
        rds_db_cluster_arns  = with.db_clusters.rows[*].cluster_arn
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

node "aws_rds_db_instance_nodes" {
  category = category.aws_rds_db_instance

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

node "aws_rds_db_instance_to_rds_db_parameter_group_node" {
  category = category.aws_rds_db_parameter_group

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
      join aws_rds_db_cluster_parameter_group as rg
        on db_parameter_group ->> 'DBParameterGroupName' = rg.name
        and rdb.account_id = rg.account_id
        and rdb.region = rg.region
    where
      rdb.arn = any($1);
  EOQ

  param "rds_db_instance_arns" {}
}

edge "aws_rds_db_instance_to_rds_db_parameter_group_edge" {
  title = "parameter group"

  sql = <<-EOQ
    select
      rdb.arn as from_id,
      rg.arn as to_id
    from
      aws_rds_db_instance as rdb
      cross join jsonb_array_elements(db_parameter_groups) as db_parameter_group
      join aws_rds_db_cluster_parameter_group as rg
        on db_parameter_group ->> 'DBParameterGroupName' = rg.name
        and rdb.account_id = rg.account_id
        and rdb.region = rg.region
    where
      rdb.arn = any($1);
  EOQ

  param "rds_db_instance_arns" {}
}

node "aws_rds_db_instance_to_rds_db_subnet_group_node" {
  category = category.aws_rds_db_subnet_group

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
      aws_rds_db_instance rdb
      join
        aws_rds_db_subnet_group as rdsg
        on rdb.db_subnet_group_name = rdsg.name
        and rdb.region = rdsg.region
        and rdb.account_id = rdsg.account_id
    where
      rdb.arn = any($1);
  EOQ

  param "rds_db_instance_arns" {}
}

edge "aws_rds_db_instance_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      instance_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as instance_arn,
      unnest($2::text[]) as key_arn;
  EOQ

  param "rds_db_instance_arns" {}
  param "key_arns" {}
}

edge "aws_rds_db_instance_rds_db_subnet_group_to_vpc_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      rdsg.arn as from_id,
      vs.subnet_id as to_id
    from
      aws_rds_db_instance as rdb
      cross join
        jsonb_array_elements(subnets) as subnet
      join
        aws_vpc_subnet as vs
        on subnet ->> 'SubnetIdentifier' = vs.subnet_id
      join
        aws_rds_db_subnet_group as rdsg
        on rdb.db_subnet_group_name = rdsg.name
        and rdb.region = rdsg.region
        and rdb.account_id = rdsg.account_id
    where
      rdb.arn = any($1);
  EOQ

  param "rds_db_instance_arns" {}
}

edge "aws_rds_db_instance_to_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      instance_arn as from_id,
      security_group_id as to_id
    from
      unnest($1::text[]) as instance_arn,
      unnest($2::text[]) as security_group_id;
  EOQ

  param "rds_db_instance_arns" {}
  param "security_group_ids" {}
}

edge "aws_rds_db_instance_vpc_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      vpc_id as to_id
    from
      unnest($1::text[]) as subnet_id,
      unnest($2::text[]) as vpc_id;
  EOQ

  param "subnet_ids" {}
  param "vpc_ids" {}
}

edge "aws_rds_db_instance_vpc_security_group_to_vpc_edge" {
  title = "subnet group"

  sql = <<-EOQ
    select
      sg.group_id as from_id,
      rdsg.arn as to_id
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
      di.arn = any($1)
      and di.vpc_id = sg.vpc_id;
  EOQ

  param "rds_db_instance_arns" {}
}

edge "aws_rds_db_instance_from_rds_db_cluster_edge" {
  title = "instance"

  sql = <<-EOQ
    select
      cluster_arn as from_id,
      instance_arn as to_id
    from
      unnest($1::text[]) as instance_arn,
      unnest($2::text[]) as cluster_arn;
  EOQ

  param "rds_db_instance_arns" {}
  param "rds_db_cluster_arns" {}
}

edge "aws_rds_db_instance_to_rds_db_snapshot_edges" {
  title = "snapshot"

  sql = <<-EOQ
    select
      instance_arn as from_id,
      snapshot_arn as to_id
    from
      unnest($1::text[]) as instance_arn,
      unnest($2::text[]) as snapshot_arn;
  EOQ

  param "rds_db_instance_arns" {}
  param "rds_db_snapshot_arns" {}
}

edge "aws_rds_db_instance_to_sns_topic_edge" {
  title = "notifies"

  sql = <<-EOQ
    select
      instance_arn as from_id,
      sns_topic_arn as to_id
    from
      unnest($1::text[]) as instance_arn,
      unnest($2::text[]) as sns_topic_arn;
  EOQ

  param "rds_db_instance_arns" {}
  param "topic_arns" {}
}
