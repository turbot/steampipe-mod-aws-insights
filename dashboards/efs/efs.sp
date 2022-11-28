locals {
  efs_common_tags = {
    service = "AWS/EFS"
  }
}

category "aws_efs_access_point" {
  title = "EFS Access Point"
  color = local.storage_color
  icon  = "text:AP"
}

category "aws_efs_file_system" {
  title = "EFS File System"
  color = local.storage_color
  icon  = "text:File"
}

category "aws_efs_mount_target" {
  title = "EFS Mount Target"
  color = local.storage_color
  icon  = "text:Target"
}