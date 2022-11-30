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

      nodes = [
        node.efs_file_system_node,
        node.efs_file_system_to_kms_key_node,
        node.efs_file_system_to_efs_access_point_node,
        node.efs_file_system_to_efs_mount_target_node,
        node.efs_file_system_mount_target_to_security_group_node,
        node.efs_file_system_mount_target_security_group_to_subnet_node,
        node.efs_file_system_mount_target_security_group_subnet_to_vpc_node
      ]

      edges = [
        edge.efs_file_system_to_kms_key_edge,
        edge.efs_file_system_to_efs_access_point_edge,
        edge.efs_file_system_to_efs_mount_target_edge,
        edge.efs_file_system_mount_target_to_security_group_edge,
        edge.efs_file_system_mount_target_security_group_to_subnet_edge,
        edge.efs_file_system_mount_target_security_group_subnet_to_vpc_edge
      ]

      args = {
        arn = self.input.efs_file_system_arn.value
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

node "efs_file_system_node" {
  category = category.efs_file_system
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
      arn = $1;
  EOQ

  param "arn" {}
}

node "efs_file_system_to_kms_key_node" {
  category = category.kms_key
  sql = <<-EOQ
    select
      arn as id,
      title as title,
      json_build_object(
        'ARN', arn,
        'Creation Date', creation_date,
        'Deletion Date', deletion_date,
        'Account ID', account_id,
        'Name', title,
        'Region', region
      ) as properties
    from
      aws_kms_key
    where
      arn in
      (
        select
          kms_key_id
        from
          aws_efs_file_system
        where
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "efs_file_system_to_kms_key_edge" {
  title = "encrypted with"
  sql = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_efs_file_system
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "efs_file_system_to_efs_access_point_node" {
  category = category.efs_access_point
  sql = <<-EOQ
    select
      a.access_point_arn as id,
      a.title as title,
      json_build_object(
        'ARN', a.access_point_arn,
        'Account ID', a.account_id,
        'Owner ID', a.owner_id,
        'Name', a.name,
        'Region', a.region
      ) as properties
    from
      aws_efs_access_point as a
      left join aws_efs_file_system as f on a.file_system_id = f.file_system_id
    where
      f.arn = $1;
  EOQ

  param "arn" {}
}

edge "efs_file_system_to_efs_access_point_edge" {
  title = "access point"
  sql = <<-EOQ
    select
      f.arn as from_id,
      a.access_point_arn as to_id
    from
      aws_efs_access_point as a
      left join aws_efs_file_system as f on a.file_system_id = f.file_system_id
    where
      f.arn = $1;
  EOQ

  param "arn" {}
}

node "efs_file_system_to_efs_mount_target_node" {
  category = category.efs_mount_target
  sql = <<-EOQ
    select
      m.mount_target_id as id,
      m.title as title,
      json_build_object(
        'Account ID', m.account_id,
        'Owner ID', m.owner_id,
        'Life Cycle State', m.life_cycle_state,
        'Region', m.region
      ) as properties
    from
      aws_efs_mount_target as m
      left join aws_efs_file_system as f on m.file_system_id = f.file_system_id
    where
      f.arn = $1;
  EOQ

  param "arn" {}
}

edge "efs_file_system_to_efs_mount_target_edge" {
  title = "mount target"
  sql = <<-EOQ
    select
      f.arn as from_id,
      m.mount_target_id as to_id
    from
      aws_efs_mount_target as m
      left join aws_efs_file_system as f on m.file_system_id = f.file_system_id
    where
      f.arn = $1;
  EOQ

  param "arn" {}
}

node "efs_file_system_mount_target_to_security_group_node" {
  category = category.vpc_security_group
  sql = <<-EOQ
    with mount_sg_list as (
      select
        jsonb_array_elements_text(security_groups) as sg,
        file_system_id
      from
        aws_efs_mount_target
    )
    select
      s.group_id as id,
      s.title as title,
      json_build_object(
        'ARN', s.arn,
        'Account ID', s.account_id,
        'Owner ID', s.owner_id,
        'Region', s.region
      ) as properties
    from
      mount_sg_list as m
      left join aws_efs_file_system as f on f.file_system_id = m.file_system_id
      left join aws_vpc_security_group as s on m.sg= s.group_id
    where
      f.arn = $1;
  EOQ

  param "arn" {}
}

edge "efs_file_system_mount_target_to_security_group_edge" {
  title = "security group"
  sql = <<-EOQ
    with mount_sg_list as (
      select
        jsonb_array_elements_text(security_groups) as sg,
        file_system_id,
        mount_target_id
      from
        aws_efs_mount_target
    )
    select
      m.mount_target_id as from_id,
      s.group_id as to_id
    from
      mount_sg_list as m
      left join aws_efs_file_system as f on f.file_system_id = m.file_system_id
      left join aws_vpc_security_group as s on m.sg= s.group_id
    where
      f.arn = $1;
  EOQ

  param "arn" {}
}

node "efs_file_system_mount_target_security_group_to_subnet_node" {
  category = category.vpc_subnet
  sql = <<-EOQ
    select
      s.subnet_id as id,
      s.title as title,
      json_build_object(
        'ARN', s.subnet_arn,
        'Account ID', s.account_id,
        'Owner ID', s.owner_id,
        'CIDR Block', s.cidr_block,
        'Region', s.region
      ) as properties
    from
      aws_efs_mount_target as m
      left join aws_efs_file_system as f on f.file_system_id = m.file_system_id
      left join aws_vpc_subnet as s on m.subnet_id= s.subnet_id
    where
      f.arn = $1;
  EOQ

  param "arn" {}
}

edge "efs_file_system_mount_target_security_group_to_subnet_edge" {
  title = "subnet"
  sql = <<-EOQ
    with mount_sg_list as (
      select
        jsonb_array_elements_text(security_groups) as sg_id,
        file_system_id,
        subnet_id
      from
        aws_efs_mount_target
    )
    select
      m.sg_id as from_id,
      s.subnet_id as to_id
    from
      mount_sg_list as m
      left join aws_efs_file_system as f on f.file_system_id = m.file_system_id
      left join aws_vpc_subnet as s on m.subnet_id= s.subnet_id
    where
      f.arn = $1;
  EOQ

  param "arn" {}
}

node "efs_file_system_mount_target_security_group_subnet_to_vpc_node" {
  category = category.vpc_vpc
  sql = <<-EOQ
    select
      v.vpc_id as id,
      v.title as title,
      json_build_object(
        'ARN', v.arn,
        'Account ID', v.account_id,
        'Owner ID', v.owner_id,
        'CIDR Block', v.cidr_block,
        'Region', v.region
      ) as properties
    from
      aws_efs_mount_target as m
      left join aws_efs_file_system as f on f.file_system_id = m.file_system_id
      left join aws_vpc as v on m.vpc_id= v.vpc_id
    where
      f.arn = $1;
  EOQ

  param "arn" {}
}

edge "efs_file_system_mount_target_security_group_subnet_to_vpc_edge" {
  title = "vpc"
  sql = <<-EOQ
    select
      m.subnet_id as from_id,
      v.vpc_id as to_id
    from
      aws_efs_mount_target as m
      left join aws_efs_file_system as f on f.file_system_id = m.file_system_id
      left join aws_vpc as v on m.vpc_id= v.vpc_id
    where
      f.arn = $1;
  EOQ

  param "arn" {}
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