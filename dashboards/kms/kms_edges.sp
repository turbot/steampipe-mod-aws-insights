edge "kms_key_to_codepipeline_pipeline" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      p.arn as from_id,
      k.id as to_id
    from
      aws_codepipeline_pipeline as p,
      aws_kms_key as k,
      jsonb_array_elements(aliases) as a
    where
      a ->> 'AliasArn' = p.encryption_key ->> 'Id'
      and p.arn = any($1);
  EOQ

  param "codepipeline_pipeline_arns" {}
}

edge "kms_key_to_kms_alias" {
  title = "key"

  sql = <<-EOQ
    select
      a.arn as from_id,
      k.arn as to_id
    from
      aws_kms_alias as a
      join aws_kms_key as k
      on a.target_key_id = k.id
    where
      k.arn = any($1);
  EOQ

  param "kms_key_arns" {}
}

