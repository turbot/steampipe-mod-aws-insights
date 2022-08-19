dashboard "aws_ebs_volume_detail" {

  title         = "AWS EBS Volume Detail"
  documentation = file("./dashboards/ebs/docs/ebs_volume_detail.md")

  tags = merge(local.ebs_common_tags, {
    type = "Detail"
  })

  input "volume_arn" {
    title = "Select a volume:"
    sql   = query.aws_ebs_volume_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_ebs_volume_storage
      args = {
        arn = self.input.volume_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ebs_volume_iops
      args = {
        arn = self.input.volume_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ebs_volume_type
      args = {
        arn = self.input.volume_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ebs_volume_attached_instances_count
      args = {
        arn = self.input.volume_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ebs_volume_encryption
      args = {
        arn = self.input.volume_arn.value
      }
    }

  }

  container {
    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_ebs_volume_relationships
      args = {
        arn = self.input.volume_arn.value
      }

      category "aws_ebs_volume" {
        icon = local.aws_ebs_volume_icon
      }

      category "aws_kms_key" {
        href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
        icon = local.aws_kms_key_icon
      }

      category "aws_ec2_instance" {
        href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.properties.'ARN' | @uri}}"
        icon = local.aws_ec2_instance_icon
      }

      category "aws_ebs_snapshot" {
        href = "${dashboard.aws_ebs_snapshot_detail.url_path}?input.snapshot_arn={{.properties.'ARN' | @uri}}"
        icon = local.aws_ebs_snapshot_icon
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
        query = query.aws_ebs_volume_overview
        args = {
          arn = self.input.volume_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_ebs_volume_tags
        args = {
          arn = self.input.volume_arn.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Attached To"
        query = query.aws_ebs_volume_attached_instances
        args = {
          arn = self.input.volume_arn.value
        }

        column "Instance ARN" {
          display = "none"
        }

        column "Instance ID" {
          href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.'Instance ARN' | @uri}}"
        }
      }

      table {
        title = "Encryption Details"
        column "KMS Key ID" {
          href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.'KMS Key ID' | @uri}}"
        }
        query = query.aws_ebs_volume_encryption_status
        args = {
          arn = self.input.volume_arn.value
        }
      }
    }
  }

  container {

    width = 12

    chart {
      title = "Read Throughput (IOPS) - Last 7 Days"
      type  = "line"
      width = 6
      sql   = <<-EOQ
        select
          timestamp,
          (sum / 3600) as read_throughput_ops
        from
          aws_ebs_volume_metric_read_ops_hourly
        where
          timestamp >= current_date - interval '7 day'
          and volume_id = reverse(split_part(reverse($1), '/', 1))
        order by timestamp
      EOQ

      param "arn" {}

      args = {
        arn = self.input.volume_arn.value
      }
    }

    chart {
      title = "Write Throughput (IOPS) - Last 7 Days"
      type  = "line"
      width = 6
      sql   = <<-EOQ
        select
          timestamp,
          (sum / 300) as write_throughput_ops
        from
          aws_ebs_volume_metric_write_ops
        where
          timestamp >= current_date - interval '7 day'
          and volume_id = reverse(split_part(reverse($1), '/', 1))
        order by timestamp;
      EOQ

      param "arn" {}

      args = {
        arn = self.input.volume_arn.value
      }
    }

  }

}

query "aws_ebs_volume_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'volume_id', volume_id
      ) as tags
    from
      aws_ebs_volume
    order by
      title;
  EOQ
}

query "aws_ebs_volume_relationships" {
  sql = <<-EOQ
    with volumes as (select arn,volume_id,title,account_id,region,size,kms_key_id from aws_ebs_volume where arn = $1)
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ebs_volume' as category,
      jsonb_build_object(
        'ID',volumes.volume_id,
        'ARN',volumes.arn,
        'Size',volumes.size,
        'Account ID', volumes.account_id,
        'Region', volumes.region,
        'KMS Key ID', volumes.kms_key_id
      ) as properties
    from
      volumes

    -- kms - nodes
    union all
    select
      null as from_id,
      null as to_id,
      kms_keys.arn as id,
      kms_keys.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', kms_keys.arn,
        'Account ID',kms_keys.account_id,
        'Region', kms_keys.region,
        'Key Manager', kms_keys.key_manager
      ) as properties
    from
      aws_kms_key as kms_keys,
      volumes
    where
      volumes.kms_key_id = kms_keys.arn

    -- kms - edges
    union all
    select
      volumes.arn as to_id,
      kms_keys.arn as from_id,
      null as id,
      'secures with' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', kms_keys.arn,
        'Account ID',kms_keys.account_id,
        'Region', kms_keys.region,
        'Key Manager', kms_keys.key_manager
      ) as properties
    from
      aws_kms_key as kms_keys,
      volumes
    where
      volumes.kms_key_id = kms_keys.arn

    -- snapshots - nodes
    union all
    select
      null as from_id,
      null as to_id,
      snapshot.snapshot_id as id,
      snapshot.snapshot_id as title,
      'aws_ebs_snapshot' as category,
      jsonb_build_object(
        'ARN', snapshot.arn,
        'Account ID',snapshot.account_id,
        'Region', snapshot.region,
        'Snapshot Size', snapshot.volume_size,
        'Snapshot ID', snapshot.snapshot_id
      ) as properties
    from
      aws_ebs_snapshot as snapshot,
      volumes
    where
      volumes.volume_id = snapshot.volume_id

    -- snapshots - edges
    union all
    select
      volumes.arn as from_id,
      snapshot.snapshot_id as to_id,
      null as id,
      'snapshot' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', snapshot.arn,
        'Account ID',snapshot.account_id,
        'Region', snapshot.region,
        'Snapshot Size', snapshot.volume_size
      ) as properties
    from
      aws_ebs_snapshot as snapshot,
      volumes
    where
      volumes.volume_id = snapshot.volume_id

    -- instances - nodes
    union all
    select
      null as from_id,
      null as to_id,
      instances.arn as id,
      instance_id as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'Name', instances.tags ->> 'Name',
        'Instance ID', instance_id,
        'ARN', instances.arn,
        'Account ID',instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_instance as instances,
      jsonb_array_elements(instances.block_device_mappings) as bdm,
      volumes
    where
      bdm -> 'Ebs' ->> 'VolumeId' in (select volume_id from volumes)

    -- instances - edges
    union all
    select
      instances.arn as from_id,
      volumes.arn as to_id,
      null as id,
      'mounts' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', instances.tags ->> 'Name',
        'Instance ID', instance_id,
        'ARN', instances.arn,
        'Account ID',instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_instance as instances,
      jsonb_array_elements(instances.block_device_mappings) as bdm,
      volumes
    where
      bdm -> 'Ebs' ->> 'VolumeId' in (select volume_id from volumes)

    -- AMI - nodes
    union all
    select
      null as from_id,
      null as to_id,
      images.image_id as id,
      images.title as title,
      'aws_ec2_ami' as category,
      jsonb_build_object(
        'SnapshotId', bdm -> 'Ebs' ->> 'SnapshotId',
        'Account ID',images.account_id,
        'Region', images.region
      ) as properties
    from
      aws_ec2_ami as images,
      jsonb_array_elements(images.block_device_mappings) as bdm,
      volumes
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' in (select snapshot_id from aws_ebs_snapshot where aws_ebs_snapshot.volume_id = volumes.volume_id)

    -- AMI - edges
    union all
    select
      bdm -> 'Ebs' ->> 'SnapshotId' as from_id,
      images.image_id as to_id,
      null as id,
      'uses snapshot' as title,
      'uses' as category,
      jsonb_build_object(
        'SnapshotId', bdm -> 'Ebs' ->> 'SnapshotId',
        'Account ID',images.account_id,
        'Region', images.region
      ) as properties
    from
      aws_ec2_ami as images,
      jsonb_array_elements(images.block_device_mappings) as bdm,
      volumes
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' in (select snapshot_id from aws_ebs_snapshot where aws_ebs_snapshot.volume_id = volumes.volume_id)

  EOQ

  param "arn" {}
}

query "aws_ebs_volume_storage" {
  sql = <<-EOQ
    select
      'Storage (GB)' as label,
      sum(size) as value
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_volume_iops" {
  sql = <<-EOQ
    select
      'IOPS' as label,
      iops as value
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_volume_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      volume_type as value
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_volume_state" {
  sql = <<-EOQ
    select
      'State' as label,
      state as value
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_volume_attached_instances_count" {
  sql = <<-EOQ
    select
      'Attached Instances' as label,
      case
        when attachments is null then 0
        else jsonb_array_length(attachments)
      end as value,
      case
        when jsonb_array_length(attachments) > 0 then 'ok'
        else 'alert'
      end as "type"
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_volume_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when encrypted then 'Enabled' else 'Disabled' end as value,
      case when encrypted then 'ok' else 'alert' end as type
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_volume_attached_instances" {
  sql = <<-EOQ
    select
      i.instance_id as "Instance ID",
      i.Tags ->> 'Name' as "Name",
      i.arn as "Instance ARN",
      i.instance_state as "Instance State",
      attachment ->> 'AttachTime' as "Attachment Time",
      (attachment ->> 'DeleteOnTermination')::boolean as "Delete on Termination"
    from
      aws_ebs_volume as v,
      jsonb_array_elements(attachments) as attachment,
      aws_ec2_instance as i
    where
      i.instance_id = attachment ->> 'InstanceId'
      and v.arn = $1
    order by
      i.instance_id;
  EOQ

  param "arn" {}
}

query "aws_ebs_volume_encryption_status" {
  sql = <<-EOQ
    select
      case when encrypted then 'Enabled' else 'Disabled' end as "Encryption",
      kms_key_id as "KMS Key ID"
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ebs_volume_overview" {
  sql = <<-EOQ
    select
      volume_id as "Volume ID",
      auto_enable_io as "Auto Enabled IO",
      snapshot_id as "Snapshot ID",
      availability_zone as "Availability Zone",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_ebs_volume
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_ebs_volume_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ebs_volume,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}
