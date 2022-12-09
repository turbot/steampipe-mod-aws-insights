locals {
  efs_common_tags = {
    service = "AWS/EFS"
  }
}

category "efs_access_point" {
  title = "EFS Access Point"
  color = local.storage_color
  icon  = "file-open"
}

category "efs_file_system" {
  title = "EFS File System"
  color = local.storage_color
  icon  = "settings-system-daydream"
}

category "efs_mount_target" {
  title = "EFS Mount Target"
  color = local.storage_color
  icon  = "text:Target"
}