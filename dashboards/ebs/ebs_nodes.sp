node "ebs_snapshot" {
  category = category.ebs_snapshot

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ID', snapshot_id,
        'ARN', arn,
        'Start Time', start_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ebs_snapshot
    where
      arn = any($1);
  EOQ

  param "ebs_snapshot_arns" {}
}

node "ebs_volume" {
  category = category.ebs_volume

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ID', volume_id,
        'ARN', arn,
        'Size', size,
        'Account ID', account_id,
        'Region', region,
        'KMS Key ID', kms_key_id
      ) as properties
    from
      aws_ebs_volume
    where
      arn = any($1);
  EOQ

  param "ebs_volume_arns" {}
}
