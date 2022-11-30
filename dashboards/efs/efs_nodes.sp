node "aws_efs_access_point_node" {
  category = category.aws_efs_access_point
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

  param "access_point_arns" {}
}

node "aws_efs_mount_target_node" {
  category = category.aws_efs_mount_target
  sql      = <<-EOQ
    select
      mount_target_id as id
    from
      aws_efs_mount_target
    where
      mount_target_id = any($1);
  EOQ

  param "mount_target_ids" {}
}