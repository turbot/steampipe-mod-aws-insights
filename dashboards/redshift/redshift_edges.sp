
edge "redshift_cluster_subnet_group_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      s.cluster_subnet_group_name as from_id,
      subnet ->> 'SubnetIdentifier' as to_id
    from
      aws_redshift_subnet_group as s
      cross join jsonb_array_elements(s.subnets) subnet
      join
        aws_redshift_cluster as c
        on c.cluster_subnet_group_name = s.cluster_subnet_group_name
        and c.region = s.region
        and c.arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}

edge "redshift_cluster_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      c.arn as from_id,
      g.arn as to_id
    from
      aws_redshift_cluster as c,
      aws_cloudwatch_log_group as g
    where
      g.title like '%' || c.title || '%'
      and c.arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}

edge "redshift_cluster_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      arn as from_id,
      r ->> 'IamRoleArn' as to_id
    from
      aws_redshift_cluster,
      jsonb_array_elements(iam_roles) as r
    where
      arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}

edge "redshift_cluster_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      kms_key_id as to_id
    from
      aws_redshift_cluster
    where
      arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}

edge "redshift_cluster_to_redshift_parameter_group" {
  title = "parameter group"

  sql = <<-EOQ
    select
      c.arn as from_id,
      g.title as to_id
    from
      aws_redshift_cluster as c,
      jsonb_array_elements(cluster_parameter_groups) as p
      left join
        aws_redshift_parameter_group as g
        on g.name = p ->> 'ParameterGroupName'
      where
        c.arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}

edge "redshift_cluster_to_redshift_snapshot" {
  title = "snapshot"

  sql = <<-EOQ
    select
      c.arn as from_id,
      s.akas::text as to_id
    from
      aws_redshift_snapshot as s,
      aws_redshift_cluster as c
    where
      s.cluster_identifier = c.cluster_identifier
      and c.arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}

edge "redshift_cluster_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    select
      c.arn as from_id,
      b.arn as to_id
    from
      aws_redshift_cluster as c,
      aws_s3_bucket as b
    where
      b.name = c.logging_status ->> 'BucketName'
      and c.arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}

edge "redshift_cluster_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      c.arn as from_id,
      s.sns_topic_arn as to_id
    from
      aws_redshift_event_subscription as s,
      jsonb_array_elements_text(source_ids_list) as ids
      join aws_redshift_cluster as c
      on ids = c.cluster_identifier
    where
      c.arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}

edge "redshift_cluster_to_vpc_eip" {
  title = "eip"

  sql = <<-EOQ
    select
      c.arn as from_id,
      e.arn as to_id
    from
      aws_redshift_cluster as c,
      aws_vpc_eip as e
    where
      c.elastic_ip_status is not null
      and e.public_ip = (c.elastic_ip_status ->> 'ElasticIp')::inet
      and c.arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}

edge "redshift_cluster_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      arn as from_id,
      s ->> 'VpcSecurityGroupId' as to_id
    from
      aws_redshift_cluster,
      jsonb_array_elements(vpc_security_groups) as s
    where
      arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}

edge "redshift_snapshot_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      akas::text as from_id,
      kms_key_id as to_id
    from
      aws_redshift_snapshot
    where
      kms_key_id is not null
      and akas::text = any($1);
  EOQ

  param "redshift_snapshot_arns" {}
}
