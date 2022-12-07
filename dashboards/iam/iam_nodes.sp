node "iam_instance_profile" {
  category = category.iam_instance_profile

  sql = <<-EOQ
    select
      iam_instance_profile_arn as id,
      split_part(iam_instance_profile_arn, ':instance-profile/',2) as title,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn,
        'Instance Profile ID', iam_instance_profile_id
      ) as properties
    from
      aws_ec2_instance as i
    where
      iam_instance_profile_arn is not null
      and i.arn = any($1);
  EOQ

  param "ec2_instance_arns" {}
}

node "iam_role" {
  category = category.iam_role

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_role
    where
      arn = any($1 ::text[]);
  EOQ

  param "iam_role_arns" {}
}