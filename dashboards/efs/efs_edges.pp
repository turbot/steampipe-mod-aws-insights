edge "efs_file_system_to_efs_access_point" {
  title = "access point"
  sql   = <<-EOQ
    with efs_access_point as (
      select
        access_point_arn,
        file_system_id
      from
        aws_efs_access_point
    ),  efs_file_system as (
      select
        file_system_id,
        arn
      from
        aws_efs_file_system
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      f.arn as from_id,
      a.access_point_arn as to_id
    from
      efs_access_point as a
      left join efs_file_system as f on a.file_system_id = f.file_system_id;
  EOQ

  param "efs_file_system_arns" {}
}

edge "efs_file_system_to_efs_mount_target" {
  title = "mount target"
  sql   = <<-EOQ
    with efs_mount_target as (
      select
        mount_target_id,
        file_system_id
      from
        aws_efs_mount_target
    ),  efs_file_system as (
      select
        file_system_id,
        arn
      from
        aws_efs_file_system
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      f.arn as from_id,
      m.mount_target_id as to_id
    from
      efs_mount_target as m
      left join aws_efs_file_system as f on m.file_system_id = f.file_system_id;
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
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
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
