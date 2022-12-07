edge "ebs_snapshot_to_ec2_ami" {
  title = "ami"

  sql = <<-EOQ
    select
      images.image_id as to_id,
      s.arn as from_id
    from
      aws_ec2_ami as images,
      jsonb_array_elements(images.block_device_mappings) as bdm,
      aws_ebs_snapshot as s
    where
      bdm -> 'Ebs' is not null
      and bdm -> 'Ebs' ->> 'SnapshotId' = s.snapshot_id
      and s.arn = any($1);
  EOQ

  param "ebs_snapshot_arns" {}
}

edge "ebs_volume_to_ebs_snapshot" {
  title = "snapshot"

  sql = <<-EOQ
    select
      v.arn as from_id,
      s.arn as to_id
    from
      aws_ebs_snapshot as s,
      aws_ebs_volume as v
    where
      s.snapshot_id = v.snapshot_id
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

edge "ebs_snapshot_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_ebs_snapshot
    where
      arn = any($1);
  EOQ

  param "ebs_snapshot_arns" {}
}