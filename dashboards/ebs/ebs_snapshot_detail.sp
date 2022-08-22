dashboard "aws_ebs_snapshot_detail" {

  title         = "AWS EBS Snapshot Detail"
  documentation = file("./dashboards/ebs/docs/ebs_snapshot_detail.md")

  tags = merge(local.ebs_common_tags, {
    type = "Detail"
  })

  input "snapshot_arn" {
    title = "Select a snapshot:"
    sql   = query.aws_ebs_snapshot_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_ebs_snapshot_storage
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
      type  = "graph"
      title = "Relationships"
      query = query.aws_ebs_snapshot_relationships_graph
      args = {
        arn = self.input.snapshot_arn.value
      }
      category "aws_ebs_snapshot" {
        icon = local.aws_ebs_snapshot_icon
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

query "aws_ebs_snapshot_age" {
  sql = <<-EOQ
    select
      'Age (days)' as label,
      (EXTRACT(epoch FROM (SELECT (NOW() - start_time)))/86400)::int as value
    from
      aws_ebs_snapshot
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_snapshot_relationships_graph" {
  sql = <<-EOQ
    with snapshot as
    (
      select
        arn,
        snapshot_id,
        volume_id,
        volume_size,
        title,
        account_id,
        region,
        kms_key_id
      from
        aws_ebs_snapshot
      where
        arn = $1
    )

    -- Resource (node)
    select
      null as from_id,
      null as to_id,
      snapshot_id as id,
      title as title,
      'aws_ebs_snapshot' as category,
      jsonb_build_object(
        'ID', snapshot.snapshot_id,
        'ARN', snapshot.arn,
        'Size', snapshot.volume_size,
        'Account ID', snapshot.account_id,
        'Region', snapshot.region,
        'KMS Key ID', snapshot.kms_key_id
      ) as properties
    from
      snapshot

    -- From EBS volumes (node)
    union all
    select
      null as from_id,
      null as to_id,
      volumes.volume_id as id,
      volumes.title as title,
      'aws_ebs_volume' as category,
      jsonb_build_object(
        'Volume ID', volumes.volume_id,
        'ARN', volumes.arn,
        'Account ID', volumes.account_id,
        'Region', volumes.region
      ) as properties
    from
      aws_ebs_volume as volumes,
      snapshot
    where
      snapshot.volume_id = volumes.volume_id

    -- From EBS volumes (edge)
    union all
    select
      volumes.volume_id as from_id,
      snapshot.snapshot_id as to_id,
      null as id,
      'snapshot' as title,
      'ebs_volume_to_ebs_snapshot' as category,
      jsonb_build_object(
        'Volume ID', volumes.volume_id,
        'Account ID', volumes.account_id,
        'Region', volumes.region
      ) as properties
    from
      aws_ebs_volume as volumes,
      snapshot
    where
      snapshot.volume_id = volumes.volume_id

    -- From EC2 AMI (node)
    union all
    select
      null as from_id,
      null as to_id,
      images.image_id as id,
      images.title as title,
      'aws_ec2_ami' as category,
      jsonb_build_object(
        'SnapshotId', bdm -> 'Ebs' ->> 'SnapshotId',
        'Account ID', images.account_id,
        'Region', images.region
      ) as properties
    from
      aws_ec2_ami as images,
      jsonb_array_elements(images.block_device_mappings) as bdm,
      snapshot
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' = snapshot.snapshot_id

    -- From EC2 AMI (edge)
    union all
    select
      images.image_id as from_id,
      bdm -> 'Ebs' ->> 'SnapshotId' as to_id,
      null as id,
      'contains' as title,
      'ec2_ami_to_ebs_snapshot' as category,
      jsonb_build_object(
        'SnapshotId', bdm -> 'Ebs' ->> 'SnapshotId',
        'Account ID', images.account_id,
        'Region', images.region
      ) as properties
    from
      aws_ec2_ami as images,
      jsonb_array_elements(images.block_device_mappings) as bdm,
      snapshot
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' = snapshot.snapshot_id

    -- From EC2 launch configurations (node)
    union all
    select
      null as from_id,
      null as to_id,
      launch_config.launch_configuration_arn as id,
      launch_config.name as title,
      'aws_ec2_launch_configuration' as category,
      jsonb_build_object(
        'ARN', launch_config.launch_configuration_arn,
        'Account ID', launch_config.account_id,
        'Region', launch_config.region
      ) as properties
    from
      aws_ec2_launch_configuration as launch_config,
      jsonb_array_elements(launch_config.block_device_mappings) as bdm,
      snapshot
    where
      bdm -> 'Ebs' ->> 'SnapshotId' = snapshot.snapshot_id

    -- From EC2 launch configurations (edge)
    union all
    select
      launch_config.launch_configuration_arn as from_id,
      snapshot.snapshot_id as to_id,
      null as id,
      'provisions EBS with' as title,
      'ec2_launch_config_to_ebs_snapshot' as category,
      jsonb_build_object(
        'ARN', launch_config.launch_configuration_arn,
        'Account ID', launch_config.account_id,
        'Region', launch_config.region
      ) as properties
    from
      aws_ec2_launch_configuration as launch_config,
      jsonb_array_elements(launch_config.block_device_mappings) as bdm,
      snapshot
    where
      bdm -> 'Ebs' ->> 'SnapshotId' = snapshot.snapshot_id

    -- To KMS Keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      kms_keys.arn as id,
      kms_keys.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', kms_keys.arn,
        'Account ID', kms_keys.account_id,
        'Region', kms_keys.region,
        'Key Manager', kms_keys.key_manager
      ) as properties
    from
      aws_kms_key as kms_keys,
      snapshot
    where
      snapshot.kms_key_id = kms_keys.arn

    -- To KMS Keys (edge)
    union all
    select
      snapshot.snapshot_id as from_id,
      kms_keys.arn as to_id,
      null as id,
      'secures with' as title,
      'ebs_snapshot_to_kms_keys' as category,
      jsonb_build_object(
        'ARN', kms_keys.arn,
        'Account ID', kms_keys.account_id,
        'Region', kms_keys.region,
        'Key Manager', kms_keys.key_manager
      ) as properties
    from
      aws_kms_key as kms_keys,
      snapshot
    where
      snapshot.kms_key_id = kms_keys.arn

    -- EBS volume > KMS Key (edge)
    union all
    select
      volumes.volume_id as from_id,
      kms_keys.arn as to_id,
      null as id,
      'secures with' as title,
      'ebs_volumes_to_kms_keys' as category,
      jsonb_build_object(
        'ARN', kms_keys.arn,
        'Account ID', kms_keys.account_id,
        'Region', kms_keys.region,
        'Key Manager', kms_keys.key_manager
      ) as properties
    from
      aws_kms_key as kms_keys,
      aws_ebs_volume as volumes,
      snapshot
    where
      snapshot.volume_id = volumes.volume_id
      and snapshot.kms_key_id = kms_keys.arn

    order by
      category,
      from_id,
      to_id;

  EOQ

  param "arn" {}
}
