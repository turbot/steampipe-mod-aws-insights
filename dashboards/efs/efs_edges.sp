edge "efs_file_system_to_efs_access_point" {
  title = "access point"
  sql   = <<-EOQ
    select
      f.arn as from_id,
      a.access_point_arn as to_id
    from
      aws_efs_access_point as a
      left join aws_efs_file_system as f on a.file_system_id = f.file_system_id
    where
      f.arn = any($1);
  EOQ

  param "efs_file_system_arns" {}
}

edge "efs_file_system_to_efs_mount_target" {
  title = "mount target"
  sql   = <<-EOQ
    select
      f.arn as from_id,
      m.mount_target_id as to_id
    from
      aws_efs_mount_target as m
      left join aws_efs_file_system as f on m.file_system_id = f.file_system_id
    where
      f.arn = any($1);
  EOQ

  param "efs_file_system_arns" {}
}

edge "efs_file_system_to_kms_key" {
  title = "encrypted with"
  sql   = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_efs_file_system
    where
      arn = any($1);
  EOQ

  param "efs_file_system_arns" {}
}

edge "efs_mount_target_to_vpc" {
  title = "vpc"
  sql   = <<-EOQ
    select
      m.subnet_id as from_id,
      v.vpc_id as to_id
    from
      aws_efs_mount_target as m
      left join aws_efs_file_system as f on f.file_system_id = m.file_system_id
      left join aws_vpc as v on m.vpc_id= v.vpc_id
    where
      f.arn = any($1);
  EOQ

  param "efs_file_system_arns" {}
}

edge "efs_mount_target_to_vpc_security_group" {
  title = "security group"
  sql   = <<-EOQ
    select
      mount_target_id as from_id,
      jsonb_array_elements_text(security_groups) as to_id
    from
        aws_efs_mount_target
    where
      mount_target_id = any($1);
  EOQ

  param "efs_mount_target_ids" {}
}

edge "efs_mount_target_to_vpc_subnet" {
  title = "subnet"
  sql   = <<-EOQ
    select
      jsonb_array_elements_text(security_groups) as from_id,
      subnet_id as to_id
    from
      aws_efs_mount_target
    where
      mount_target_id = any($1);
  EOQ

  param "efs_mount_target_ids" {}
}
