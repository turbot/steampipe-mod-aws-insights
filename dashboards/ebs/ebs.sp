locals {
  ebs_common_tags = {
    service = "AWS/EBS"
  }
}

category "ebs_snapshot" {
  title = "EBS Snapshot"
  href  = "/aws_insights.dashboard.ebs_snapshot_detail?input.ebs_snapshot_arn={{.properties.'ARN' | @uri}}"
  color = local.storage_color
  icon  = "heroicons-outline:viewfinder-circle"
}

category "ebs_volume" {
  title = "EBS Volume"
  href  = "/aws_insights.dashboard.ebs_volume_detail?input.volume_arn={{.properties.'ARN' | @uri}}"
  icon  = "heroicons-outline:inbox-stack"
  color = local.storage_color
}
