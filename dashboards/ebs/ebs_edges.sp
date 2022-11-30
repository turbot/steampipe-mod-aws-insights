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