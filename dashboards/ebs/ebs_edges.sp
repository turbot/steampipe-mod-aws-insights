edge "ebs_volume_ebs_snapshots_to_ec2_ami" {
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

edge "ebs_snapshot_from_ebs_volume" {
  title = "snapshot"

  sql = <<-EOQ
    select
      volume_arn as from_id,
      snapshot_arn as to_id
    from
      unnest($1::text[]) as volume_arn,
      unnest($2::text[]) as snapshot_arn
  EOQ

  param "volume_arns" {}
  param "snapshot_arns" {}
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

  param "launch_configuration_arns" {}
  param "snapshot_arns" {}
}

edge "ebs_snapshot_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      snapshot_arn as to_id,
      key_arn as from_id
    from
      unnest($2::text[]) as snapshot_arn,
      unnest($1::text[]) as key_arn
  EOQ

  param "snapshot_arns" {}
  param "key_arns" {}
}