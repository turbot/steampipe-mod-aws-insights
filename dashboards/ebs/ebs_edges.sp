edge "ebs_volume_ebs_snapshots_to_ec2_ami" {
  title = "ami"

  sql = <<-EOQ
    select
      ec2_image_id as to_id,
      ebs_snapshot_arn as from_id
    from
      unnest($1::text[]) as ec2_image_id,
      unnest($2::text[]) as ebs_snapshot_arn
  EOQ

  param "ec2_image_ids" {}
  param "ebs_snapshot_arns" {}
}

edge "ebs_snapshot_from_ebs_volume" {
  title = "snapshot"

  sql = <<-EOQ
    select
      ebs_volume_arn as from_id,
      ebs_snapshot_arn as to_id
    from
      unnest($1::text[]) as ebs_volume_arn,
      unnest($2::text[]) as ebs_snapshot_arn
  EOQ

  param "ebs_volume_arns" {}
  param "ebs_snapshot_arns" {}
}

edge "ebs_snapshot_from_ec2_launch_configuration" {
  title = "snapshot"

  sql = <<-EOQ
    select
      launch_configuration as from_id,
      snapshot_arn as to_id
    from
      unnest($1::text[]) as launch_configuration,
      unnest($2::text[]) as snapshot_arn
  EOQ

  param "ec2_launch_configuration_arns" {}
  param "ebs_snapshot_arns" {}
}

edge "ebs_snapshot_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      ebs_snapshot_arn as to_id,
      kms_key_arn as from_id
    from
      unnest($2::text[]) as ebs_snapshot_arn,
      unnest($1::text[]) as kms_key_arn
  EOQ

  param "ebs_snapshot_arns" {}
  param "kms_key_arns" {}
}