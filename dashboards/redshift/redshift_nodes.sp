node "redshift_cluster" {
  category = category.redshift_cluster

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Cluster Status', cluster_status,
        'Cluster Version', cluster_version,
        'Public', publicly_accessible::text,
        'Encrypted', encrypted::text
      ) as properties
    from
      aws_redshift_cluster
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "redshift_cluster_arns" {}
}

node "redshift_parameter_group" {
  category = category.redshift_parameter_group

  sql = <<-EOQ
    select
      g.title as id,
      g.title as title,
      jsonb_build_object(
        'ARN', g.title,
        'Description', g.description,
        'Family', g.family
      ) as properties
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

node "redshift_snapshot" {
  category = category.redshift_snapshot

  sql = <<-EOQ
    select
      akas::text as id,
      title,
      jsonb_build_object(
        'Status', status,
        'Cluster Identifier', cluster_identifier,
        'Create Time', cluster_create_time,
        'Type', snapshot_type,
        'Encrypted', encrypted::text,
        'Account ID', account_id,
        'Source Region', source_region
      ) as properties
    from
      aws_redshift_snapshot
    where
      akas::text = any($1);
  EOQ

  param "redshift_snapshot_arns" {}
}

node "redshift_subnet_group" {
  category = category.redshift_subnet_group

  sql = <<-EOQ
    select
      s.cluster_subnet_group_name as id,
      s.cluster_subnet_group_name as title,
      jsonb_build_object(
        'AKAS', s.akas,
        'Description', s.description,
        'Status', s.subnet_group_status,
        'Vpc ID', s.vpc_id
      ) as properties
    from
      aws_redshift_cluster as c
      left join
        aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name
        and c.arn = any($1);
  EOQ

  param "redshift_cluster_arns" {}
}
