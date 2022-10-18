dashboard "aws_ebs_snapshot_detail" {

  title         = "AWS EBS Snapshot Detail"
  documentation = file("./dashboards/ebs/docs/ebs_snapshot_detail.md")

  tags = merge(local.ebs_common_tags, {
    type = "Detail"
  })

  input "snapshot_arn" {
    title = "Select a snapshot:"
    query = query.aws_ebs_snapshot_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_ebs_snapshot_state
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ebs_snapshot_storage
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ebs_snapshot_encryption
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ebs_snapshot_age
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"


      nodes = [
        node.aws_ebs_snapshot_node,
        node.aws_ebs_snapshot_from_ebs_volume_node,
        node.aws_ebs_snapshot_from_ec2_ami_node,
        node.aws_ebs_snapshot_from_ec2_launch_configuration_node,
        node.aws_ebs_snapshot_to_kms_key_node
      ]

      edges = [
        edge.aws_ebs_snapshot_from_ebs_volume_edge,
        edge.aws_ebs_snapshot_from_ec2_ami_edge,
        edge.aws_ebs_snapshot_from_ec2_launch_configuration_edge,
        edge.aws_ebs_snapshot_to_kms_key_edge
      ]

      args = {
        arn = self.input.snapshot_arn.value
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.aws_ebs_snapshot_overview
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    table {
      title = "Tags"
      width = 3
      query = query.aws_ebs_snapshot_tags
      args = {
        arn = self.input.snapshot_arn.value
      }
    }
  }
}

query "aws_ebs_snapshot_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'volume_id', volume_id,
        'state', state
      ) as tags
    from
      aws_ebs_snapshot
    order by
      title;
  EOQ
}

query "aws_ebs_snapshot_overview" {
  sql = <<-EOQ
    select
      snapshot_id as "Snapshot ID",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_ebs_snapshot
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_ebs_snapshot_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ebs_snapshot,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_ebs_snapshot_storage" {
  sql = <<-EOQ
    select
      'Storage (GB)' as label,
      volume_size as value
    from
      aws_ebs_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_snapshot_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when encrypted then 'Enabled' else 'Disabled' end as value,
      case when encrypted then 'ok' else 'alert' end as type
    from
      aws_ebs_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_snapshot_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(state) as value
    from
      aws_ebs_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_snapshot_age" {
  sql = <<-EOQ
    with data as (
      select
        (EXTRACT(epoch FROM (SELECT (NOW() - start_time)))/86400)::int as age
      from
        aws_ebs_snapshot
      where
        arn = $1
    )
    select
      'Age (in Days)' as label,
      age as value,
      case when age<35 then 'ok' else 'alert' end as type
    from
      data;
  EOQ

  param "arn" {}
}

node "aws_ebs_snapshot_node" {
  category = category.aws_ebs_snapshot

  sql = <<-EOQ
    select
      snapshot_id as id,
      title as title,
      jsonb_build_object(
        'ID', s.snapshot_id,
        'ARN', s.arn,
        'Size', s.volume_size,
        'KMS Key ID', s.kms_key_id
      ) as properties
    from
      aws_ebs_snapshot as s
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ebs_snapshot_from_ebs_volume_node" {
  category = category.aws_ebs_volume

  sql = <<-EOQ
    select
      volumes.volume_id as id,
      volumes.title as title,
      jsonb_build_object(
        'Volume ID', volumes.volume_id,
        'ARN', volumes.arn
      ) as properties
    from
      aws_ebs_snapshot as s
    left join 
      aws_ebs_volume as volumes 
      on s.volume_id = volumes.volume_id
      and s.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ebs_snapshot_from_ebs_volume_edge" {
  title = "snapshot"

  sql = <<-EOQ
    select
      volumes.volume_id as from_id,
      s.snapshot_id as to_id
    from
      aws_ebs_snapshot as s
    left join 
      aws_ebs_volume as volumes 
      on s.volume_id = volumes.volume_id
      and s.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ebs_snapshot_from_ec2_ami_node" {
  category = category.aws_ec2_ami

  sql = <<-EOQ
    select
      images.image_id as id,
      images.title as title,
      jsonb_build_object(
        'Image ID', images.image_id,
        'Snapshot ID', bdm -> 'Ebs' ->> 'SnapshotId'
      ) as properties
    from
      aws_ec2_ami as images,
      jsonb_array_elements(images.block_device_mappings) as bdm,
      aws_ebs_snapshot as s
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' = s.snapshot_id
      and s.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ebs_snapshot_from_ec2_ami_edge" {
  title = "created from"

  sql = <<-EOQ
    select
      images.image_id as from_id,
      bdm -> 'Ebs' ->> 'SnapshotId' as to_id
    from
      aws_ec2_ami as images,
      jsonb_array_elements(images.block_device_mappings) as bdm,
      aws_ebs_snapshot as s
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' = s.snapshot_id
      and s.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ebs_snapshot_from_ec2_launch_configuration_node" {
  category = category.aws_ec2_launch_configuration

  sql = <<-EOQ
    select
      launch_config.launch_configuration_arn as id,
      launch_config.name as title,
      jsonb_build_object(
        'ARN', launch_config.launch_configuration_arn,
        'Account ID', launch_config.account_id,
        'Region', launch_config.region
      ) as properties
    from
      aws_ec2_launch_configuration as launch_config,
      jsonb_array_elements(launch_config.block_device_mappings) as bdm,
      aws_ebs_snapshot as s
    where
      bdm -> 'Ebs' ->> 'SnapshotId' = s.snapshot_id
      and s.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ebs_snapshot_from_ec2_launch_configuration_edge" {
  title = "provisions EBS with"

  sql = <<-EOQ
    select
      launch_config.launch_configuration_arn as from_id,
      s.snapshot_id as to_id
    from
      aws_ec2_launch_configuration as launch_config,
      jsonb_array_elements(launch_config.block_device_mappings) as bdm,
      aws_ebs_snapshot as s
    where
      bdm -> 'Ebs' ->> 'SnapshotId' = s.snapshot_id
      and s.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ebs_snapshot_to_kms_key_node" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      kms_keys.arn as id,
      kms_keys.title as title,
      jsonb_build_object(
        'ARN', kms_keys.arn,
        'Key Manager', kms_keys.key_manager
      ) as properties
    from
      aws_ebs_snapshot as s
    left join 
      aws_kms_key as kms_keys
      on s.kms_key_id = kms_keys.arn
      and s.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ebs_snapshot_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      s.snapshot_id as from_id,
      kms_keys.arn as to_id
    from
      aws_ebs_snapshot as s
    left join 
      aws_kms_key as kms_keys
      on s.kms_key_id = kms_keys.arn
      and s.arn = $1;
  EOQ

  param "arn" {}
}
