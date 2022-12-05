
node "efs_file_system" {
  category = category.efs_file_system
  sql      = <<-EOQ
      select
        arn as id,
        title as title,
        json_build_object(
          'ARN', arn,
          'ID', file_system_id,
          'Name', name,
          'State', life_cycle_state,
          'Created At', creation_time,
          'Account ID', account_id,
          'Region', region
        ) as properties
      from
        aws_efs_file_system
      where
        arn = any($1);
  EOQ

  param "efs_file_system_arns" {}
}

node "efs_access_point" {
  category = category.efs_access_point
  sql      = <<-EOQ
    select
      access_point_arn as id,
      title as title,
      json_build_object(
        'ARN', access_point_arn,
        'Account ID', account_id,
        'Owner ID', owner_id,
        'Name', name,
        'Region', region
      ) as properties
    from
      aws_efs_access_point
    where
      access_point_arn = any($1);
  EOQ

  param "efs_access_point_arns" {}
}

node "efs_mount_target" {
  category = category.efs_mount_target
  sql      = <<-EOQ
    select
      mount_target_id as id,
      title as title,
      json_build_object(
        'ID', mount_target_id,
        'Account ID', account_id,
        'Owner ID', owner_id,
        'File System Id', file_system_id,
        'Region', region
      ) as properties
    from
      aws_efs_mount_target
    where
      mount_target_id = any($1);
  EOQ

  param "efs_mount_target_ids" {}
}