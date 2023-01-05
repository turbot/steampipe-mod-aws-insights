dashboard "ebs_volume_detail" {

  title         = "AWS EBS Volume Detail"
  documentation = file("./dashboards/ebs/docs/ebs_volume_detail.md")

  tags = merge(local.ebs_common_tags, {
    type = "Detail"
  })

  input "volume_arn" {
    title = "Select a volume:"
    query = query.ebs_volume_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ebs_volume_storage
      args  = [self.input.volume_arn.value]
    }

    card {
      width = 2
      query = query.ebs_volume_iops
      args  = [self.input.volume_arn.value]
    }

    card {
      width = 2
      query = query.ebs_volume_type
      args  = [self.input.volume_arn.value]
    }

    card {
      width = 2
      query = query.ebs_volume_attached_instances_count
      args  = [self.input.volume_arn.value]
    }

    card {
      width = 2
      query = query.ebs_volume_encryption
      args  = [self.input.volume_arn.value]
    }
  }

  with "ebs_snapshots" {
    query = query.ebs_volume_ebs_snapshots
    args  = [self.input.volume_arn.value]
  }

  with "ec2_amis" {
    query = query.ebs_volume_ec2_amis
    args  = [self.input.volume_arn.value]
  }

  with "ec2_instances" {
    query = query.ebs_volume_ec2_instances
    args  = [self.input.volume_arn.value]
  }

  with "kms_keys" {
    query = query.ebs_volume_kms_keys
    args  = [self.input.volume_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.ebs_snapshot
        args = {
          ebs_snapshot_ids = with.ebs_snapshots.rows[*].snapshot_id
        }
      }

      node {
        base = node.ebs_shared_snapshot
        args = {
          ebs_snapshot_ids = with.ebs_snapshots.rows[*].snapshot_id
        }
      }

      node {
        base = node.ebs_volume
        args = {
          ebs_volume_arns = [self.input.volume_arn.value]
        }
      }

      node {
        base = node.ec2_ami
        args = {
          ec2_ami_image_ids = with.ec2_amis.rows[*].image_id
        }
      }

      node {
        base = node.ec2_instance
        args = {
          ec2_instance_arns = with.ec2_instances.rows[*].instance_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys.rows[*].key_arn
        }
      }

      edge {
        base = edge.ebs_snapshot_to_ec2_ami
        args = {
          ebs_snapshot_ids = with.ebs_snapshots.rows[*].snapshot_id
        }
      }

      edge {
        base = edge.ebs_snapshot_to_ebs_volume
        args = {
          ebs_snapshot_ids = with.ebs_snapshots.rows[*].snapshot_id
        }
      }

      edge {
        base = edge.ebs_volume_to_kms_key
        args = {
          ebs_volume_arns = [self.input.volume_arn.value]
        }
      }

      edge {
        base = edge.ec2_instance_to_ebs_volume
        args = {
          ec2_instance_arns = with.ec2_instances.rows[*].instance_arn
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
        query = query.ebs_volume_overview
        args  = [self.input.volume_arn.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.ebs_volume_tags
        args  = [self.input.volume_arn.value]
      }
    }

    container {

      width = 6

      table {
        title = "Attached To"
        query = query.ebs_volume_attached_instances
        args  = [self.input.volume_arn.value]

        column "Instance ARN" {
          display = "none"
        }

        column "Instance ID" {
          href = "${dashboard.ec2_instance_detail.url_path}?input.instance_arn={{.'Instance ARN' | @uri}}"
        }
      }

      table {
        title = "Encryption Details"
        column "KMS Key ID" {
          href = "${dashboard.kms_key_detail.url_path}?input.key_arn={{.'KMS Key ID' | @uri}}"
        }
        query = query.ebs_volume_encryption_status
        args  = [self.input.volume_arn.value]
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

      args = [self.input.volume_arn.value]
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

      args = [self.input.volume_arn.value]
    }

  }

}

# Input queries

query "ebs_volume_input" {
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

# With queries

query "ebs_volume_ebs_snapshots" {
  sql = <<-EOQ
    select
      s.snapshot_id as snapshot_id
    from
      aws_ebs_volume as v
      join aws_ebs_snapshot as s on s.snapshot_id = v.snapshot_id
    where
      v.account_id = s.account_id
      and s.arn is not null
      and v.arn = $1;
  EOQ
}

query "ebs_volume_ec2_amis" {
  sql = <<-EOQ
    select
      a.image_id as image_id
    from
      aws_ebs_volume as v,
      aws_ebs_snapshot as s,
      aws_ec2_ami as a,
      jsonb_array_elements(block_device_mappings) as s_id
    where
      v.snapshot_id = s.snapshot_id
      and s_id -> 'Ebs'->> 'SnapshotId' = s.snapshot_id
      and v.arn = $1
  EOQ
}

query "ebs_volume_ec2_instances" {
  sql = <<-EOQ
    select
      e.arn as instance_arn
    from
      aws_ebs_volume as v,
      jsonb_array_elements(attachments) as a,
      aws_ec2_instance as e
    where
      a ->> 'InstanceId' = e.instance_id
      and v.arn = $1;
  EOQ
}

query "ebs_volume_kms_keys" {
  sql = <<-EOQ
    select
      kms_key_id as key_arn
    from
      aws_ebs_volume
    where
      kms_key_id is not null
      and arn = $1;
  EOQ
}

# Card queries

query "ebs_volume_storage" {
  sql = <<-EOQ
    select
      'Storage (GB)' as label,
      sum(size) as value
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ
}

query "ebs_volume_iops" {
  sql = <<-EOQ
    select
      'IOPS' as label,
      iops as value
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ
}

query "ebs_volume_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      volume_type as value
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ
}

query "ebs_volume_state" {
  sql = <<-EOQ
    select
      'State' as label,
      state as value
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ
}

query "ebs_volume_attached_instances_count" {
  sql = <<-EOQ
    select
      'Attached Instances' as label,
      case
        when jsonb_array_length(attachments) = 0 then 0
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
}

query "ebs_volume_encryption" {
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
}

query "ebs_volume_attached_instances" {
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
}

query "ebs_volume_encryption_status" {
  sql = <<-EOQ
    select
      case when encrypted then 'Enabled' else 'Disabled' end as "Encryption",
      kms_key_id as "KMS Key ID"
    from
      aws_ebs_volume
    where
      arn = $1;
  EOQ
}

# Other detail page queries

query "ebs_volume_overview" {
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
}

query "ebs_volume_tags" {
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
}
