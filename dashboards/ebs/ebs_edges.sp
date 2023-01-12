edge "ebs_snapshot_to_ec2_ami" {
  title = "ami"

  sql = <<-EOQ
    select
      images.image_id as to_id,
      bdm -> 'Ebs' ->> 'SnapshotId' as from_id
    from
      aws_ec2_ami as images,
      jsonb_array_elements(images.block_device_mappings) as bdm
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' = any($1);
  EOQ

  param "ebs_snapshot_ids" {}
}

edge "ebs_snapshot_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      snapshot_id as from_id,
      kms_key_id as to_id
    from
      aws_ebs_snapshot
    where
      snapshot_id = any($1);
  EOQ

  param "ebs_snapshot_ids" {}
}

edge "ebs_snapshot_to_ebs_volume" {
  title = "volume"

  sql = <<-EOQ
    select
      v.snapshot_id as from_id,
      v.arn as to_id
    from
      aws_ebs_volume as v
    where
      v.snapshot_id = any($1);
  EOQ

  param "ebs_snapshot_ids" {}
}

edge "ebs_volume_to_ebs_snapshot" {
  title = "snapshot"

  sql = <<-EOQ
    select
      v.arn as from_id,
      s.snapshot_id as to_id
    from
      aws_ebs_snapshot as s,
      aws_ebs_volume as v
    where
      s.volume_id = v.volume_id
      and v.arn = any($1);
  EOQ

  param "ebs_volume_arns" {}
}

edge "ebs_volume_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_ebs_volume as v
    where
      v.arn = any($1);
  EOQ

  param "ebs_volume_arns" {}
}
