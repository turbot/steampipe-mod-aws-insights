
edge "efs_file_system_to_kms_key" {
  title = "encrypted with"
  sql   = <<-EOQ
    select
      efs_file_system_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as efs_file_system_arn,
      unnest($2::text[]) as key_arn
  EOQ

  param "efs_file_system_arns" {}
  param "key_arns" {}
}

edge "efs_file_system_to_efs_access_point" {
  title = "access point"
  sql   = <<-EOQ
    select
      efs_file_system_arn as from_id,
      access_point_arn as to_id
    from
      unnest($1::text[]) as efs_file_system_arn,
      unnest($2::text[]) as access_point_arn
  EOQ

  param "efs_file_system_arns" {}
  param "access_point_arns" {}
}

edge "efs_file_system_to_efs_mount_target" {
  title = "mount target"
  sql   = <<-EOQ
    select
      efs_file_system_arn as from_id,
      mount_target_id as to_id
    from
      unnest($1::text[]) as efs_file_system_arn,
      unnest($2::text[]) as mount_target_id
  EOQ

  param "efs_file_system_arns" {}
  param "mount_target_ids" {}
}

edge "efs_file_system_mount_target_to_security_group" {
  title = "security group"
  sql   = <<-EOQ
    select
      mount_target_id as from_id,
      group_id as to_id
    from
      unnest($1::text[]) as mount_target_id,
      unnest($2::text[]) as group_id
  EOQ

  param "mount_target_ids" {}
  param "security_group_ids" {}
}

edge "efs_file_system_mount_target_security_group_to_subnet" {
  title = "subnet"
  sql   = <<-EOQ
    select
      security_group_id as from_id,
      subnet_id as to_id
    from
      unnest($1::text[]) as security_group_id,
      unnest($2::text[]) as subnet_id
  EOQ

  param "security_group_ids" {}
  param "subnet_ids" {}
}

edge "efs_file_system_mount_target_security_group_subnet_to_vpc" {
  title = "vpc"
  sql   = <<-EOQ
    select
      subnet_id as to_id,
      vpc_id as from_id
    from
      unnest($2::text[]) as subnet_id,
      unnest($1::text[]) as vpc_id
  EOQ

  param "subnet_ids" {}
  param "vpc_ids" {}
}
