node "sagemaker_notebook_instance" {
  category = category.sagemaker_notebook_instance

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Status', notebook_instance_status,
        'Instance Type', instance_type,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_sagemaker_notebook_instance
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "sagemaker_notebook_instance_arns" {}
}
