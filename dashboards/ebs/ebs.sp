locals {
  ebs_common_tags = {
    service = "AWS/EBS"
  }
}

category "aws_ebs_snapshot" {
  title = "EBS Snapshot"
  href  = "/aws_insights.dashboard.aws_ebs_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
  color = local.storage_color
  icon  = "viewfinder-circle"
}

category "aws_ebs_volume" {
  title = "EBS Volume"
  href  = "/aws_insights.dashboard.aws_ebs_volume_detail?input.volume_arn={{.properties.'ARN' | @uri}}"
  icon  = "inbox-stack"
  color = local.storage_color
}
