locals {
  efs_common_tags = {
    service = "AWS/EFS"
  }
}

category "efs_access_point" {
  title = "EFS Access Point"
  color = local.storage_color
  icon  = "folder_open"
}

category "efs_file_system" {
  title = "EFS File System"
  color = local.storage_color
  icon  = "home_storage"
}

category "efs_mount_target" {
  title = "EFS Mount Target"
  color = local.storage_color
  icon  = "cloud_sync"
}