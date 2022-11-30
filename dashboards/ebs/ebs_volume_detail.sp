dashboard "aws_ebs_volume_detail" {

  title         = "AWS EBS Volume Detail"
  documentation = file("./dashboards/ebs/docs/ebs_volume_detail.md")

  tags = merge(local.ebs_common_tags, {
    type = "Detail"
  })

  input "volume_arn" {
    title = "Select a volume:"
    query = query.aws_ebs_volume_input
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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "kms_keys" {
        sql = <<-EOQ
          select
            kms_key_id as key_arn
          from
            aws_ebs_volume
          where
            kms_key_id is not null
            and arn = $1;
        EOQ

        args = [self.input.volume_arn.value]
      }

      with "snapshots" {
        sql = <<-EOQ
          select
            s.arn as snapshot_arn
          from
            aws_ebs_volume as v,
            aws_ebs_snapshot as s
          where
            s.snapshot_id = v.snapshot_id
            and v.arn = $1;
        EOQ

        args = [self.input.volume_arn.value]
      }

      with "instances" {
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

        args = [self.input.volume_arn.value]
      }

      with "amis" {
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

        args = [self.input.volume_arn.value]
      }

      nodes = [
        node.aws_ebs_volume_nodes,
        node.aws_kms_key_nodes,
        node.aws_ebs_snapshot_nodes,
        node.aws_ec2_instance_nodes,
        node.aws_ec2_ami_node
      ]

      edges = [
        edge.aws_ebs_volume_to_kms_key_edge,
        edge.aws_ebs_volume_to_ebs_snapshot_edge,
        edge.aws_ec2_instance_to_ebs_volume_edge,
        edge.aws_ebs_volume_ebs_snapshots_to_ec2_ami_edge
      ]

      args = {
        volume_arns   = [self.input.volume_arn.value]
        key_arns      = with.kms_keys.rows[*].key_arn
        snapshot_arns = with.snapshots.rows[*].snapshot_arn
        instance_arns = with.instances.rows[*].instance_arn
        image_ids     = with.amis.rows[*].image_id
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

edge "aws_ebs_volume_to_kms_key_edge" {
  title = "encrypted with"
  sql   = <<-EOQ
    select
      key_arns as to_id,
      volume_arns as from_id
    from
      unnest($1::text[]) as key_arns,
      unnest($2::text[]) as volume_arns
  EOQ

  param "key_arns" {}
  param "volume_arns" {}
}

edge "aws_ebs_volume_to_ebs_snapshot_edge" {
  title = "snapshot"

  sql = <<-EOQ
    select
      snapshot_arns as to_id,
      volume_arns as from_id
    from
      unnest($1::text[]) as snapshot_arns,
      unnest($2::text[]) as volume_arns
  EOQ

  param "snapshot_arns" {}
  param "volume_arns" {}
}

edge "aws_ec2_instance_to_ebs_volume_edge" {
  title = "mounts"

  sql = <<-EOQ
    select
      volume_arns as to_id,
      instance_arns as from_id
    from
      unnest($1::text[]) as volume_arns,
      unnest($2::text[]) as instance_arns
  EOQ

  param "volume_arns" {}
  param "instance_arns" {}
}

edge "aws_ebs_volume_ebs_snapshots_to_ec2_ami_edge" {
  title = "ami"

  sql = <<-EOQ
    select
      image_ids as to_id,
      snapshot_arns as from_id
    from
      unnest($1::text[]) as image_ids,
      unnest($2::text[]) as snapshot_arns
  EOQ

  param "image_ids" {}
  param "snapshot_arns" {}
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


//******


node "aws_ebs_volume_nodes" {
  category = category.aws_ebs_volume

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ID', volume_id,
        'ARN', arn,
        'Size', size,
        'Account ID', account_id,
        'Region', region,
        'KMS Key ID', kms_key_id
      ) as properties
    from
      aws_ebs_volume
    where
      arn = any($1);
  EOQ

  param "volume_arns" {}
}
