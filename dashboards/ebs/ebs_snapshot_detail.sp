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
    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_ebs_snapshot_relationships
      args  = {
        arn = self.input.snapshot_arn.value
      }

      category "aws_kms_key" {
        href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kms_key_light.svg"))
      }

      category "aws_ebs_volume" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ebs_volume_light.svg"))
      }
      
      category "aws_ec2_instance" {
        href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.properties.'ARN' | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_instance_light.svg"))
      }

      category "aws_ebs_snapshot" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ebs_snapshot_light.svg"))
      }

    }
  }
}

query "aws_ebs_snapshot_input" {
  sql = <<-EOQ
    select
      title as label,
      snpshot_id as value,
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

query "aws_ebs_snapshot_relationships" {
  sql = <<-EOQ
    with snapshot as (select arn,snapshot_id,volume_id,volume_size,title,account_id,region,kms_key_id from aws_ebs_snapshot where arn = $1)
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
      
    -- EBS - nodes
    union all
    select
      null as from_id,
      null as to_id,
      volumes.volume_id as id,
      volumes.title as title,
      'aws_ebs_volume' as category,
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
      
    -- EBS - nodes
    union all
    select
      snapshot.snapshot_id as from_id,
      volumes.volume_id as to_id,
      null as id,
      'snapshot of' as title,
      'aws_ebs_volume' as category,
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
      snapshot
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' = snapshot.snapshot_id
      
    -- AMI - edges
    union all
    select
      bdm -> 'Ebs' ->> 'SnapshotId' as to_id,
      images.image_id as from_id,
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
      snapshot
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' = snapshot.snapshot_id


  EOQ
  
  param "arn" {}
}