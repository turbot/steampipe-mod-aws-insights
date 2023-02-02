dashboard "ebs_snapshot_detail" {

  title         = "AWS EBS Snapshot Detail"
  documentation = file("./dashboards/ebs/docs/ebs_snapshot_detail.md")

  tags = merge(local.ebs_common_tags, {
    type = "Detail"
  })

  input "ebs_snapshot_id" {
    title = "Select a snapshot:"
    query = query.ebs_snapshot_input
    width = 4
  }

  container {
    card {
      width = 3
      query = query.ebs_snapshot_state
      args  = [self.input.ebs_snapshot_id.value]
    }

    card {
      width = 3
      query = query.ebs_snapshot_storage
      args  = [self.input.ebs_snapshot_id.value]
    }
    card {
      width = 3
      query = query.ebs_snapshot_encryption
      args  = [self.input.ebs_snapshot_id.value]
    }

    card {
      width = 3
      query = query.ebs_snapshot_age
      args  = [self.input.ebs_snapshot_id.value]
    }
  }

  with "target_ebs_volumes_for_ebs_snapshot" {
    query = query.target_ebs_volumes_for_ebs_snapshot
    args  = [self.input.ebs_snapshot_id.value]
  }

  with "source_ebs_volumes_for_ebs_snapshot" {
    query = query.source_ebs_volumes_for_ebs_snapshot
    args  = [self.input.ebs_snapshot_id.value]
  }

  with "ec2_amis_for_ebs_snapshot" {
    query = query.ec2_amis_for_ebs_snapshot
    args  = [self.input.ebs_snapshot_id.value]
  }

  with "ec2_launch_configurations_for_ebs_snapshot" {
    query = query.ec2_launch_configurations_for_ebs_snapshot
    args  = [self.input.ebs_snapshot_id.value]
  }

  with "kms_keys_for_ebs_snapshot" {
    query = query.kms_keys_for_ebs_snapshot
    args  = [self.input.ebs_snapshot_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.ebs_snapshot
        args = {
          ebs_snapshot_ids = [self.input.ebs_snapshot_id.value]
        }
      }

      node {
        base = node.ebs_volume
        args = {
          ebs_volume_arns = with.target_ebs_volumes_for_ebs_snapshot.rows[*].volume_arn
        }
      }

      node {
        base = node.ebs_volume
        args = {
          ebs_volume_arns = with.source_ebs_volumes_for_ebs_snapshot.rows[*].volume_arn
        }
      }

      node {
        base = node.ec2_ami
        args = {
          ec2_ami_image_ids = with.ec2_amis_for_ebs_snapshot.rows[*].image_id
        }
      }

      node {
        base = node.ec2_launch_configuration
        args = {
          ec2_launch_configuration_arns = with.ec2_launch_configurations_for_ebs_snapshot.rows[*].launch_configuration_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_ebs_snapshot.rows[*].key_arn
        }
      }

      edge {
        base = edge.ebs_snapshot_to_ec2_ami
        args = {
          ebs_snapshot_ids = [self.input.ebs_snapshot_id.value]
        }
      }

      edge {
        base = edge.ebs_snapshot_to_kms_key
        args = {
          ebs_snapshot_ids = [self.input.ebs_snapshot_id.value]
        }
      }

      edge {
        base = edge.ebs_snapshot_to_ebs_volume
        args = {
          ebs_snapshot_ids = [self.input.ebs_snapshot_id.value]
        }
      }

      edge {
        base = edge.ebs_volume_to_ebs_snapshot
        args = {
          ebs_volume_arns = with.source_ebs_volumes_for_ebs_snapshot.rows[*].volume_arn
        }
      }

      edge {
        base = edge.ec2_launch_configuration_to_ebs_snapshot
        args = {
          ebs_snapshot_ids = [self.input.ebs_snapshot_id.value]
        }
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.ebs_snapshot_overview
      args  = [self.input.ebs_snapshot_id.value]
    }

    table {
      title = "Tags"
      width = 3
      query = query.ebs_snapshot_tags
      args  = [self.input.ebs_snapshot_id.value]
    }
  }
}

# Input queries

query "ebs_snapshot_input" {
  sql = <<-EOQ
    select
      title as label,
      snapshot_id as value,
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

# With queries

query "target_ebs_volumes_for_ebs_snapshot" {
  sql = <<-EOQ
    select
      v.arn as volume_arn
    from
      aws_ebs_volume as v
    where
      v.snapshot_id = $1;
  EOQ
}

query "source_ebs_volumes_for_ebs_snapshot" {
  sql = <<-EOQ
    select
      v.arn as volume_arn
    from
      aws_ebs_snapshot as s,
      aws_ebs_volume as v
    where
      s.volume_id = v.volume_id
      and s.snapshot_id = $1;
  EOQ
}

query "ec2_amis_for_ebs_snapshot" {
  sql = <<-EOQ
    select
      images.image_id as image_id
    from
      aws_ec2_ami as images,
      jsonb_array_elements(images.block_device_mappings) as bdm,
      aws_ebs_snapshot as s
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' = s.snapshot_id
      and s.snapshot_id = $1;
  EOQ
}

query "ec2_launch_configurations_for_ebs_snapshot" {
  sql = <<-EOQ
    select
      launch_config.launch_configuration_arn as launch_configuration_arn
    from
      aws_ec2_launch_configuration as launch_config,
      jsonb_array_elements(launch_config.block_device_mappings) as bdm,
      aws_ebs_snapshot as s
    where
      bdm -> 'Ebs' ->> 'SnapshotId' = s.snapshot_id
      and s.snapshot_id = $1;
  EOQ
}

query "kms_keys_for_ebs_snapshot" {
  sql = <<-EOQ
    select
      kms_key_id as key_arn
    from
      aws_ebs_snapshot
    where
      kms_key_id is not null
      and snapshot_id = $1
  EOQ
}

# Card queries

query "ebs_snapshot_storage" {
  sql = <<-EOQ
    select
      'Storage (GB)' as label,
      volume_size as value
    from
      aws_ebs_snapshot
    where
      snapshot_id = $1;
  EOQ
}

query "ebs_snapshot_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when encrypted then 'Enabled' else 'Disabled' end as value,
      case when encrypted then 'ok' else 'alert' end as type
    from
      aws_ebs_snapshot
    where
      snapshot_id = $1;
  EOQ
}

query "ebs_snapshot_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(state) as value
    from
      aws_ebs_snapshot
    where
      snapshot_id = $1;
  EOQ
}

query "ebs_snapshot_age" {
  sql = <<-EOQ
    with data as (
      select
        (extract(epoch from (select (now() - start_time)))/86400)::int as age
      from
        aws_ebs_snapshot
      where
        snapshot_id = $1
    )
    select
      'Age (in Days)' as label,
      age as value,
      case when age<35 then 'ok' else 'alert' end as type
    from
      data;
  EOQ
}


# Other detail page queries

query "ebs_snapshot_overview" {
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
      snapshot_id = $1
  EOQ
}

query "ebs_snapshot_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ebs_snapshot,
      jsonb_array_elements(tags_src) as tag
    where
      snapshot_id = $1
    order by
      tag ->> 'Key';
  EOQ
}
