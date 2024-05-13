edge "emr_cluster_to_ec2_ami" {
  title = "ami"

  sql = <<-EOQ
    select
      id as from_id,
      custom_ami_id as to_id
    from
      aws_emr_cluster
      join unnest($1::text[]) as a on cluster_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_cluster_to_emr_instance_fleet" {
  title = "instance fleet"

  sql = <<-EOQ
    with emr_instance_fleet as (
      select
        id,
        cluster_id
      from
        aws_emr_instance_fleet
    ), emr_cluster as (
      select
        id,
        cluster_arn
      from
        aws_emr_cluster
        join unnest($1::text[]) as a on cluster_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      c.id as from_id,
      f.id as to_id
    from
      emr_cluster as c
      join emr_instance_fleet as f on f.cluster_id = c.id;
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_cluster_to_emr_instance_group" {
  title = "instance group"

  sql = <<-EOQ
    with emr_instance_group as (
      select
        id,
        cluster_id
      from
        aws_emr_instance_group
    ), emr_cluster as (
      select
        id,
        cluster_arn
      from
        aws_emr_cluster
        join unnest($1::text[]) as a on cluster_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      c.id as from_id,
      g.id as to_id
    from
      emr_cluster as c
      join emr_instance_group as g on g.cluster_id = c.id;
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_cluster_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      c.id as from_id,
      r.arn as to_id
    from
      aws_emr_cluster as c
      join unnest($1::text[]) as a on c.cluster_arn = a and c.account_id = split_part(a, ':', 5) and c.region = split_part(a, ':', 4),
      aws_iam_role as r
    where
      r.arn = c.service_role;
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_cluster_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    with s3_bucket as (
      select
        name,
        arn
      from
        aws_s3_bucket
    ),  emr_cluster as (
      select
        id,
        cluster_arn,
        log_uri
      from
        aws_emr_cluster
        join unnest($1::text[]) as a on cluster_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      c.id as from_id,
      b.arn as to_id
    from
      emr_cluster as c
      left join s3_bucket as b on split_part(log_uri, '/', 3) = b.name
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_instance_fleet_to_emr_instance" {
  title = "ec2 instance"

  sql = <<-EOQ
    with emr_instance as (
      select
        id,
        state,
        cluster_id,
        instance_fleet_id
      from
        aws_emr_instance
      where
        state <> 'TERMINATED'
        and instance_fleet_id is not null
    ),  emr_cluster as (
      select
        id,
        cluster_arn
      from
        aws_emr_cluster
        join unnest($1::text[]) as a on cluster_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      instance_fleet_id as from_id,
      i.id as to_id
    from
      emr_cluster as c
      join emr_instance as i on i.cluster_id = c.id;
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_instance_group_to_emr_instance" {
  title = "ec2 instance"

  sql = <<-EOQ
     with emr_instance as (
      select
        id,
        cluster_id,
        instance_group_id
      from
        aws_emr_instance
      where
        instance_group_id is not null
        and state <> 'TERMINATED'
    ),  emr_cluster as (
      select
        id,
        cluster_arn
      from
        aws_emr_cluster
        join unnest($1::text[]) as a on cluster_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      instance_group_id as from_id,
      i.id as to_id
    from
      emr_cluster as c
      join emr_instance as i on i.cluster_id = c.id
  EOQ

  param "emr_cluster_arns" {}
}
