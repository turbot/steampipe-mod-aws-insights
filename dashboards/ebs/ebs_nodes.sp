node "ebs_snapshot" {
  category = category.ebs_snapshot

  sql = <<-EOQ
    select
      snapshot_id as id,
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
      snapshot_id = any($1)
      and owner_id = account_id;
  EOQ

  param "ebs_snapshot_ids" {}
}

node "ebs_shared_snapshot" {
  category = category.ebs_shared_snapshot

  sql = <<-EOQ
    select
      snapshot_id as id,
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
      snapshot_id = any($1)
      and owner_id <> account_id;
  EOQ

  param "ebs_snapshot_ids" {}
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
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ebs_volume_arns" {}
}
