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

      with "rds_db_cluster_snapshots" {
        sql = <<-EOQ
          select
            s.arn as snapshot_arn
          from
            aws_rds_db_cluster as c
            join aws_rds_db_cluster_snapshot as s
            on s.db_cluster_identifier = c.db_cluster_identifier
          where
            c.arn = $1;
        EOQ

        args = [self.input.db_cluster_arn.value]
      }

      with "iam_roles" {
        sql = <<-EOQ
          select
            roles ->> 'RoleArn' as role_arn
          from
            aws_rds_db_cluster
            cross join jsonb_array_elements(associated_roles) as roles
          where
            arn = $1;
        EOQ

        args = [self.input.db_cluster_arn.value]
      }

      with "sns_topics" {
        sql = <<-EOQ
          select
            s.sns_topic_arn as topic_arn
          from
            aws_rds_db_event_subscription as s,
            jsonb_array_elements_text(source_ids_list) as ids
            join aws_rds_db_cluster as c
            on ids = c.db_cluster_identifier
          where
            c.arn = $1;
        EOQ

        args = [self.input.db_cluster_arn.value]
      }

      with "rds_db_instances" {
        sql = <<-EOQ
          select
            i.arn as instance_arn
          from
            aws_rds_db_instance as i
            join
              aws_rds_db_cluster as c
              on i.db_cluster_identifier = c.db_cluster_identifier
          where
            c.arn = $1;
        EOQ

        args = [self.input.db_cluster_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            kms_key_id as key_arn
          from
            aws_rds_db_cluster
          where
            arn = $1;
        EOQ

        args = [self.input.db_cluster_arn.value]
      }

      with "vpc_security_groups" {
        sql = <<-EOQ
          select
            csg ->> 'VpcSecurityGroupId' as group_id
          from
            aws_rds_db_cluster as c
            cross join
              jsonb_array_elements(c.vpc_security_groups) as csg
          where
            c.arn = $1;
        EOQ

        args = [self.input.db_cluster_arn.value]
      }

      with "vpc_subnets" {
        sql = <<-EOQ
          select
            vs ->> 'SubnetIdentifier' as subnet_id
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
            rdc.arn = $1;
        EOQ

        args = [self.input.db_cluster_arn.value]
      }

      with "vpc_vpcs" {
        sql = <<-EOQ
          select
            distinct v.vpc_id as vpc_id
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

        args = [self.input.db_cluster_arn.value]
      }

      nodes = [
        node.rds_db_cluster,
        node.iam_role,
        node.sns_topic,
        node.rds_db_cluster_snapshot,
        node.rds_db_instance,
        node.rds_db_cluster_parameter_group,
        node.rds_db_subnet_group,
        node.kms_key,
        node.vpc_security_group,
        node.vpc_subnet,
        node.vpc_vpc
      ]

      edges = [
        edge.rds_db_cluster_to_sns_topic,
        edge.rds_db_cluster_to_iam_role,
        edge.rds_db_cluster_to_rds_db_cluster_snapshot,
        edge.rds_db_cluster_to_rds_db_instance,
        edge.rds_db_cluster_to_rds_db_cluster_parameter_group,
        edge.rds_db_cluster_to_kms_key,
        edge.rds_db_cluster_to_vpc_security_group,
        edge.rds_db_subnet_group_to_vpc_subnet,
        edge.vpc_subnet_to_vpc_vpc,
        edge.vpc_security_group_to_rds_db_subnet_group
      ]

      args = {
        rds_db_cluster_arns          = [self.input.db_cluster_arn.value]
        rds_db_instance_arns         = with.rds_db_instances.rows[*].instance_arn
        rds_db_cluster_snapshot_arns = with.rds_db_cluster_snapshots.rows[*].snapshot_arn
        sns_topic_arns               = with.sns_topics.rows[*].topic_arn
        kms_key_arns                 = with.kms_keys.rows[*].key_arn
        vpc_vpc_ids                  = with.vpc_vpcs.rows[*].vpc_id
        vpc_subnet_ids               = with.vpc_subnets.rows[*].subnet_id
        vpc_security_group_ids       = with.vpc_security_groups.rows[*].group_id
        iam_role_arns                = with.iam_roles.rows[*].role_arn
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
      initcap(status) as value,
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
      aws_rds_db_cluster rdc
      left join
        aws_rds_db_subnet_group as rdsg
        on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
    where
      rdc.arn = any($1);
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

edge "vpc_security_group_to_rds_db_subnet_group" {
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
      c.arn = any($1);
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
