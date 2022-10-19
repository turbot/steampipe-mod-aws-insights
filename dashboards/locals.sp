locals {
  aws_iam_user_mandatory_sql = <<EOT
    select
      user_id as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'Path', path,
        'Create Date', create_date,
        'MFA Enabled', mfa_enabled::text,
        'Account ID', account_id 
      ) as properties
    __QUERY_PREDICATE__
  EOT
}
