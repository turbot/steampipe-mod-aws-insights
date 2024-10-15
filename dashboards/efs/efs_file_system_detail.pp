dashboard "efs_file_system_detail" {

  title         = "AWS EFS File System Detail"
  documentation = file("./dashboards/efs/docs/efs_file_system_detail.md")

  tags = merge(local.efs_common_tags, {
    type = "Detail"
  })

  input "efs_file_system_arn" {
    title = "Select a file system:"
    query = query.efs_file_system_input
    width = 4
  }

  container {

    card {
      query = query.efs_file_system_status
      width = 2
      args  = [self.input.efs_file_system_arn.value]
    }

    card {
      query = query.efs_file_system_performance_mode
      width = 2
      args  = [self.input.efs_file_system_arn.value]
    }

    card {
      query = query.efs_file_system_throughput_mode
      width = 2
      args  = [self.input.efs_file_system_arn.value]
    }

    card {
      query = query.efs_file_system_mount_targets
      width = 2
      args  = [self.input.efs_file_system_arn.value]
    }

    card {
      query = query.efs_file_system_encryption
      width = 2
      args  = [self.input.efs_file_system_arn.value]
    }

    card {
      query = query.efs_file_system_automatic_backup
      width = 2
      args  = [self.input.efs_file_system_arn.value]
    }

  }
  with "efs_access_points_for_efs_file_system" {
    query = query.efs_access_points_for_efs_file_system
    args  = [self.input.efs_file_system_arn.value]
  }

  with "efs_mount_targets_for_efs_file_system" {
    query = query.efs_mount_targets_for_efs_file_system
    args  = [self.input.efs_file_system_arn.value]
  }

  with "kms_keys_for_efs_file_system" {
    query = query.kms_keys_for_efs_file_system
    args  = [self.input.efs_file_system_arn.value]
  }

  with "vpc_security_groups_for_efs_file_system" {
    query = query.vpc_security_groups_for_efs_file_system
    args  = [self.input.efs_file_system_arn.value]
  }

  with "vpc_subnets_for_efs_file_system" {
    query = query.vpc_subnets_for_efs_file_system
    args  = [self.input.efs_file_system_arn.value]
  }

  with "vpc_vpcs_for_efs_file_system" {
    query = query.vpc_vpcs_for_efs_file_system
    args  = [self.input.efs_file_system_arn.value]
  }
  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.efs_access_point
        args = {
          efs_access_point_arns = with.efs_access_points_for_efs_file_system.rows[*].access_point_arn
        }
      }

      node {
        base = node.efs_file_system
        args = {
          efs_file_system_arns = [self.input.efs_file_system_arn.value]
        }
      }

      node {
        base = node.efs_mount_target
        args = {
          efs_mount_target_ids = with.efs_mount_targets_for_efs_file_system.rows[*].mount_target_id
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_efs_file_system.rows[*].key_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_efs_file_system.rows[*].security_group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_efs_file_system.rows[*].subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_efs_file_system.rows[*].vpc_id
        }
      }

      edge {
        base = edge.efs_file_system_to_efs_access_point
        args = {
          efs_file_system_arns = [self.input.efs_file_system_arn.value]
        }
      }

      edge {
        base = edge.efs_file_system_to_efs_mount_target
        args = {
          efs_file_system_arns = [self.input.efs_file_system_arn.value]
        }
      }

      edge {
        base = edge.efs_file_system_to_kms_key
        args = {
          efs_file_system_arns = [self.input.efs_file_system_arn.value]
        }
      }

      edge {
        base = edge.efs_mount_target_to_vpc_security_group
        args = {
          efs_mount_target_ids = with.efs_mount_targets_for_efs_file_system.rows[*].mount_target_id
        }
      }

      edge {
        base = edge.efs_mount_target_to_vpc_subnet
        args = {
          efs_mount_target_ids = with.efs_mount_targets_for_efs_file_system.rows[*].mount_target_id
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_efs_file_system.rows[*].subnet_id
        }
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
        query = query.efs_file_system_overview
        args  = [self.input.efs_file_system_arn.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.efs_file_system_tags
        args  = [self.input.efs_file_system_arn.value]
      }

    }

    container {
      width = 6

      table {
        title = "Size in Bytes"
        // type  = "line"
        query = query.efs_file_system_size_in_bytes
        args  = [self.input.efs_file_system_arn.value]
      }

    }

  }
}


query "efs_file_system_input" {
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

# card queries

query "efs_file_system_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      life_cycle_state as value
    from
      aws_efs_file_system
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

query "efs_file_system_performance_mode" {
  sql = <<-EOQ
    select
      'Performance Mode' as label,
      performance_mode as value
    from
      aws_efs_file_system
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

query "efs_file_system_throughput_mode" {
  sql = <<-EOQ
    select
      'Throughput Mode' as label,
      throughput_mode as value
    from
      aws_efs_file_system
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

query "efs_file_system_mount_targets" {
  sql = <<-EOQ
    select
      'Mount Targets' as label,
      number_of_mount_targets as value
    from
      aws_efs_file_system
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

query "efs_file_system_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when encrypted then 'Enabled' else 'Disabled' end as value,
      case when encrypted then 'ok' else 'alert' end as type
    from
      aws_efs_file_system
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

query "efs_file_system_automatic_backup" {
  sql = <<-EOQ
    select
      'Automatic Backup' as label,
      case when automatic_backups = 'enabled' then 'Enabled' else 'Disabled' end as value,
      case when automatic_backups = 'enabled' then 'ok' else 'alert' end as type
    from
      aws_efs_file_system
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

# with queries

query "efs_access_points_for_efs_file_system" {
  sql = <<-EOQ
    with efs_file_system_id as (
      select
        file_system_id
      from
        aws_efs_file_system
      where
        arn = $1
        and account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    )
    select
      a.access_point_arn as access_point_arn
    from
      aws_efs_access_point a
    join
      efs_file_system_id efs on efs.file_system_id = a.file_system_id;
  EOQ
}

query "efs_mount_targets_for_efs_file_system" {
  sql = <<-EOQ
    with efs_details as (
      select
        file_system_id
      from
        aws_efs_file_system
      where
        arn = $1
        and account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    )
    select
      mt.mount_target_id
    from
      aws_efs_mount_target mt
    join
      efs_details ed on mt.file_system_id = ed.file_system_id;
  EOQ
}

query "kms_keys_for_efs_file_system" {
  sql = <<-EOQ
    select
      kms_key_id as key_arn
    from
      aws_efs_file_system
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_security_groups_for_efs_file_system" {
  sql = <<-EOQ
    select
      jsonb_array_elements_text(t.security_groups) as security_group_id
    from
      aws_efs_file_system as s,
      aws_efs_mount_target as t
    where
      s.file_system_id = t.file_system_id
      and s.arn = $1
      and s.account_id = split_part($1, ':', 5)
      and s.region = split_part($1, ':', 4);
  EOQ
}

query "vpc_subnets_for_efs_file_system" {
  sql = <<-EOQ
    with relevant_mount_targets as (
      select
        m.subnet_id
      from
        aws_efs_mount_target m
      join
        aws_efs_file_system f on f.file_system_id = m.file_system_id
      where
        f.arn = $1
        and f.account_id = split_part($1, ':', 5)
        and f.region = split_part($1, ':', 4)
    )
    select
      s.subnet_id as subnet_id
    from
      aws_vpc_subnet s
    join
      relevant_mount_targets rmt on rmt.subnet_id = s.subnet_id;
  EOQ
}

query "vpc_vpcs_for_efs_file_system" {
  sql = <<-EOQ
    with efs_mount_details as (
      select
        m.vpc_id
      from
        aws_efs_mount_target m
      join
        aws_efs_file_system f on f.file_system_id = m.file_system_id
      where
        f.arn = $1
        and f.account_id = split_part($1, ':', 5)
        and f.region = split_part($1, ':', 4)
    )
    select
      v.vpc_id as vpc_id
    from
      aws_vpc v
    join
      efs_mount_details emd on emd.vpc_id = v.vpc_id;
  EOQ
} 

# table queries

query "efs_file_system_overview" {
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
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}

query "efs_file_system_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_efs_file_system,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
    order by
      tag ->> 'Key';
  EOQ

}

query "efs_file_system_size_in_bytes" {
  sql = <<-EOQ
    select
      size_in_bytes ->> 'Value' as "Total Size",
      size_in_bytes ->> 'ValueInStandard' as "Size in Standard / One Zone",
      size_in_bytes ->> 'ValueInIA' as "Size in Standard-IA / One Zone-IA"
    from
      aws_efs_file_system
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ

}
