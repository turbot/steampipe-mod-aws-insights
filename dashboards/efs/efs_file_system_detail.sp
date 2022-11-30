dashboard "aws_efs_file_system_detail" {

  title         = "AWS EFS File System Detail"
  documentation = file("./dashboards/efs/docs/efs_file_system_detail.md")

  tags = merge(local.efs_common_tags, {
    type = "Detail"
  })

  input "efs_file_system_arn" {
    title = "Select a file system:"
    query = query.aws_efs_file_system_input
    width = 4
  }

  container {

    card {
      query = query.aws_efs_file_system_status
      width = 2
      args = {
        arn = self.input.efs_file_system_arn.value
      }
    }

    card {
      query = query.aws_efs_file_system_performance_mode
      width = 2
      args = {
        arn = self.input.efs_file_system_arn.value
      }
    }

    card {
      query = query.aws_efs_file_system_throughput_mode
      width = 2
      args = {
        arn = self.input.efs_file_system_arn.value
      }
    }

    card {
      query = query.aws_efs_file_system_mount_targets
      width = 2
      args = {
        arn = self.input.efs_file_system_arn.value
      }
    }

    card {
      query = query.aws_efs_file_system_encryption
      width = 2
      args = {
        arn = self.input.efs_file_system_arn.value
      }
    }

    card {
      query = query.aws_efs_file_system_automatic_backup
      width = 2
      args = {
        arn = self.input.efs_file_system_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "kms_keys" {
        sql = <<-EOQ
        select
          kms_key_id as key_arn
        from
          aws_efs_file_system
        where
          arn = $1
      EOQ

        args = [self.input.efs_file_system_arn.value]
      }

      with "security_groups" {
        sql = <<-EOQ
          select
            jsonb_array_elements_text(t.security_groups) as security_group_id
          from
            aws_efs_file_system as s,
            aws_efs_mount_target as t
          where
            s.file_system_id = t.file_system_id
            and s.arn = $1
        EOQ

        args = [self.input.efs_file_system_arn.value]
      }
      
      with "access_points" {
        sql = <<-EOQ
          select
            a.access_point_arn as access_point_arn
          from
            aws_efs_access_point as a
            left join aws_efs_file_system as f on a.file_system_id = f.file_system_id
          where
            f.arn = $1;
        EOQ

        args = [self.input.efs_file_system_arn.value]
      }

      with "mount_targets" {
        sql = <<-EOQ
          select
            mount_target_id
          from
            aws_efs_mount_target as m
            left join aws_efs_file_system as f on m.file_system_id = f.file_system_id
          where
            f.arn = $1;
        EOQ

        args = [self.input.efs_file_system_arn.value]
      }

      with "subnets" {
        sql = <<-EOQ
          select
            s.subnet_id as subnet_id
          from
            aws_efs_mount_target as m
            left join aws_efs_file_system as f on f.file_system_id = m.file_system_id
            left join aws_vpc_subnet as s on m.subnet_id = s.subnet_id
          where
            f.arn = $1;
        EOQ

        args = [self.input.efs_file_system_arn.value]
      }

      with "vpcs" {
        sql = <<-EOQ
          select
            v.vpc_id as vpc_id
          from
            aws_efs_mount_target as m
            left join aws_efs_file_system as f on f.file_system_id = m.file_system_id
            left join aws_vpc as v on m.vpc_id= v.vpc_id
          where
            f.arn = $1;
        EOQ

        args = [self.input.efs_file_system_arn.value]
      }

      nodes = [
        node.aws_efs_file_system_node,
        node.aws_kms_key_nodes,
        node.aws_efs_access_point_node,
        node.aws_efs_mount_target_node,
        node.aws_vpc_security_group_nodes,
        node.aws_vpc_subnet_nodes,
        node.aws_vpc_nodes
      ]

      edges = [
        edge.aws_efs_file_system_to_kms_key_edge,
        edge.aws_efs_file_system_to_efs_access_point_edge,
        edge.aws_efs_file_system_to_efs_mount_target_edge,
        edge.aws_efs_file_system_mount_target_to_security_group_edge,
        edge.aws_efs_file_system_mount_target_security_group_to_subnet_edge,
        edge.aws_efs_file_system_mount_target_security_group_subnet_to_vpc_edge
      ]

      args = {
        efs_file_system_arns = [self.input.efs_file_system_arn.value]
        key_arns             = with.kms_keys.rows[*].key_arn
        security_group_ids   = with.security_groups.rows[*].security_group_id
        access_point_arns    = with.access_points.rows[*].access_point_arn
        mount_target_ids     = with.mount_targets.rows[*].mount_target_id
        subnet_ids           = with.subnets.rows[*].subnet_id
        vpc_ids              = with.vpcs.rows[*].vpc_id
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
        query = query.aws_efs_file_system_overview
        args = {
          arn = self.input.efs_file_system_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_efs_file_system_tags
        args = {
          arn = self.input.efs_file_system_arn.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Size in Bytes"
        // type  = "line"
        query = query.aws_efs_file_system_size_in_bytes
        args = {
          arn = self.input.efs_file_system_arn.value
        }
      }

    }

  }
}


query "aws_efs_file_system_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'id', file_system_id
      ) as tags
    from
      aws_efs_file_system
    order by
      title;
  EOQ
}

query "aws_efs_file_system_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      life_cycle_state as value
    from
      aws_efs_file_system
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_efs_file_system_performance_mode" {
  sql = <<-EOQ
    select
      'Performance Mode' as label,
      performance_mode as value
    from
      aws_efs_file_system
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_efs_file_system_throughput_mode" {
  sql = <<-EOQ
    select
      'Throughput Mode' as label,
      throughput_mode as value
    from
      aws_efs_file_system
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_efs_file_system_mount_targets" {
  sql = <<-EOQ
    select
      'Mount Targets' as label,
      number_of_mount_targets as value
    from
      aws_efs_file_system
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_efs_file_system_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when encrypted then 'Enabled' else 'Disabled' end as value,
      case when encrypted then 'ok' else 'alert' end as type
    from
      aws_efs_file_system
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_efs_file_system_automatic_backup" {
  sql = <<-EOQ
    select
      'Automatic Backup' as label,
      case when automatic_backups = 'enabled' then 'Enabled' else 'Disabled' end as value,
      case when automatic_backups = 'enabled' then 'ok' else 'alert' end as type
    from
      aws_efs_file_system
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_efs_file_system_node" {
  category = category.aws_efs_file_system
    sql = <<-EOQ
      select
        arn as id,
        title as title,
        json_build_object(
          'ARN', arn,
          'ID', file_system_id,
          'Name', name,
          'State', life_cycle_state,
          'Created At', creation_time,
          'Account ID', account_id,
          'Region', region
        ) as properties
      from
        aws_efs_file_system
      where
        arn = any($1);
  EOQ

  param "efs_file_system_arns" {}
}

edge "aws_efs_file_system_to_kms_key_edge" {
  title = "encrypted with"
  sql   = <<-EOQ
    select
      efs_file_system_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as efs_file_system_arn,
      unnest($2::text[]) as key_arn
  EOQ

  param "efs_file_system_arns" {}
  param "key_arns" {}
}

edge "aws_efs_file_system_to_efs_access_point_edge" {
  title = "access point"
  sql   = <<-EOQ
    select
      efs_file_system_arn as from_id,
      access_point_arn as to_id
    from
      unnest($1::text[]) as efs_file_system_arn,
      unnest($2::text[]) as access_point_arn
  EOQ

  param "efs_file_system_arns" {}
  param "access_point_arns" {}
}

edge "aws_efs_file_system_to_efs_mount_target_edge" {
  title = "mount target"
  sql   = <<-EOQ
    select
      efs_file_system_arn as from_id,
      mount_target_id as to_id
    from
      unnest($1::text[]) as efs_file_system_arn,
      unnest($2::text[]) as mount_target_id
  EOQ

  param "efs_file_system_arns" {}
  param "mount_target_ids" {}
}

edge "aws_efs_file_system_mount_target_to_security_group_edge" {
  title = "security group"
  sql   = <<-EOQ
    select
      mount_target_id as from_id,
      group_id as to_id
    from
      unnest($1::text[]) as mount_target_id,
      unnest($2::text[]) as group_id
  EOQ

  param "mount_target_ids" {}
  param "security_group_ids" {}
}

edge "aws_efs_file_system_mount_target_security_group_to_subnet_edge" {
  title = "subnet"
  sql   = <<-EOQ
    select
      security_group_id as from_id,
      subnet_id as to_id
    from
      unnest($1::text[]) as security_group_id,
      unnest($2::text[]) as subnet_id
  EOQ

  param "security_group_ids" {}
  param "subnet_ids" {}
}

edge "aws_efs_file_system_mount_target_security_group_subnet_to_vpc_edge" {
  title = "vpc"
  sql   = <<-EOQ
    select
      subnet_id as to_id,
      vpc_id as from_id
    from
      unnest($2::text[]) as subnet_id,
      unnest($1::text[]) as vpc_id
  EOQ

  param "subnet_ids" {}
  param "vpc_ids" {}
}

query "aws_efs_file_system_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      creation_time as "Creation Time",
      file_system_id as "ID",
      region as "Region",
      arn as "ARN",
      account_id as "Account ID",
      kms_key_id as "KMS Key ID"
    from
      aws_efs_file_system
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_efs_file_system_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_efs_file_system,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_efs_file_system_size_in_bytes" {
  sql = <<-EOQ
    select
      size_in_bytes ->> 'Value' as "Total Size",
      size_in_bytes ->> 'ValueInStandard' as "Size in Standard / One Zone",
      size_in_bytes ->> 'ValueInIA' as "Size in Standard-IA / One Zone-IA"
    from
      aws_efs_file_system
    where
      arn = $1;
  EOQ

  param "arn" {}
}