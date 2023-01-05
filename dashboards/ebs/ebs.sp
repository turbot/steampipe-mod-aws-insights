locals {
  ebs_common_tags = {
    service = "AWS/EBS"
  }
}

category "ebs_snapshot" {
  title = "EBS Snapshot"
  color = local.storage_color
  href  = "/aws_insights.dashboard.ebs_snapshot_detail?input.ebs_snapshot_id={{.properties.'ID' | @uri}}"
  icon  = "add_a_photo"
}

category "ebs_shared_snapshot" {
  title = "EBS Shared Snapshot"
  color = local.storage_color
  icon  = "add_a_photo"
}

category "ebs_volume" {
  title = "EBS Volume"
  color = local.storage_color
  href  = "/aws_insights.dashboard.ebs_volume_detail?input.volume_arn={{.properties.'ARN' | @uri}}"
  icon  = "hard_drive"
}
