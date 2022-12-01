dashboard "ebs_snapshot_detail" {

  title         = "AWS EBS Snapshot Detail"
  documentation = file("./dashboards/ebs/docs/ebs_snapshot_detail.md")

  tags = merge(local.ebs_common_tags, {
    type = "Detail"
  })

  input "snapshot_arn" {
    title = "Select a snapshot:"
    query = query.ebs_snapshot_input
    width = 4
  }

  container {
    card {
      width = 2
      query = query.ebs_snapshot_state
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      width = 2
      query = query.ebs_snapshot_storage
      args = {
        arn = self.input.snapshot_arn.value
      }
    }
    card {
      width = 2
      query = query.ebs_snapshot_encryption
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    card {
      width = 2
      query = query.ebs_snapshot_age
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

      with "ebs_volumes" {
        sql = <<-EOQ
          select
            v.arn as volume_arn
          from
            aws_ebs_snapshot as s,
            aws_ebs_volume as v where s.snapshot_id = v.snapshot_id
            and s.arn = $1;
        EOQ

        args = [self.input.snapshot_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
        select
          kms_key_id as key_arn
        from
          aws_ebs_snapshot
        where
          kms_key_id is not null
          and arn = $1
      EOQ

        args = [self.input.snapshot_arn.value]
      }

      with "amis" {
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
            and s.arn = $1;
        EOQ

        args = [self.input.snapshot_arn.value]
      }

      with "launch_configurations" {
        sql = <<-EOQ
          select
            launch_config.launch_configuration_arn as launch_configuration_arn
          from
            aws_ec2_launch_configuration as launch_config,
            jsonb_array_elements(launch_config.block_device_mappings) as bdm,
            aws_ebs_snapshot as s
          where
            bdm -> 'Ebs' ->> 'SnapshotId' = s.snapshot_id
            and s.arn = $1;
        EOQ

        args = [self.input.snapshot_arn.value]
      }

      nodes = [
        node.ebs_snapshot,
        node.ebs_volume,
        node.ec2_ami,
        node.ec2_launch_configuration,
        node.kms_key
      ]

      edges = [
        edge.ebs_snapshot_from_ebs_volume,
        edge.ebs_snapshot_from_ec2_launch_configuration,
        edge.ebs_snapshot_to_kms_key
        edge.ebs_volume_ebs_snapshots_to_ec2_ami,
      ]

      args = {
        snapshot_arns             = [self.input.snapshot_arn.value]
        volume_arns               = with.ebs_volumes.rows[*].volume_arn
        key_arns                  = with.kms_keys.rows[*].key_arn
        image_ids                 = with.amis.rows[*].image_id
        launch_configuration_arns = with.launch_configurations.rows[*].launch_configuration_arn
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.ebs_snapshot_overview
      args = {
        arn = self.input.snapshot_arn.value
      }
    }

    table {
      title = "Tags"
      width = 3
      query = query.ebs_snapshot_tags
      args = {
        arn = self.input.snapshot_arn.value
      }
    }
  }
}

query "ebs_snapshot_input" {
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
      arn = $1
  EOQ

  param "arn" {}
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
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "ebs_snapshot_storage" {
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

query "ebs_snapshot_encryption" {
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

query "ebs_snapshot_state" {
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

query "ebs_snapshot_age" {
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

