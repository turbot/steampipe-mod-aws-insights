edge "emr_cluster_to_ec2_ami" {
  title = "ami"

  sql = <<-EOQ
    select
      id as from_id,
      custom_ami_id as to_id
    from
      aws_emr_cluster
    where
      cluster_arn = any($1);
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_cluster_to_emr_instance_fleet" {
  title = "instance fleet"

  sql = <<-EOQ
    select
      c.id as from_id,
      f.id as to_id
    from
      aws_emr_cluster as c
      left join
        aws_emr_instance_fleet as f
        on f.cluster_id = c.id
    where
      cluster_arn = any($1);
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_cluster_to_emr_instance_group" {
  title = "instance group"

  sql = <<-EOQ
    select
      c.id as from_id,
      g.id as to_id
    from
      aws_emr_cluster as c
      left join
        aws_emr_instance_group as g
        on g.cluster_id = c.id
    where
      cluster_arn = any($1);
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
      aws_iam_role as r,
      aws_emr_cluster as c
    where
      c.cluster_arn = any($1)
      and r.name = c.service_role;
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_cluster_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    select
      c.id as from_id,
      b.arn as to_id
    from
      aws_emr_cluster as c
      left join
        aws_s3_bucket as b
        on split_part(log_uri, '/', 3) = b.name
    where
      cluster_arn = any($1);
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_instance_fleet_to_emr_instance" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      instance_fleet_id as from_id,
      i.id as to_id
    from
      aws_emr_cluster as c
      left join
        aws_emr_instance as i
        on i.cluster_id = c.id
    where
      cluster_arn = any($1)
      and instance_fleet_id is not null
      and i.state <> 'TERMINATED';
  EOQ

  param "emr_cluster_arns" {}
}

edge "emr_instance_group_to_emr_instance" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      instance_group_id as from_id,
      i.id as to_id
    from
      aws_emr_cluster as c
      left join
        aws_emr_instance as i
        on i.cluster_id = c.id
    where
      cluster_arn = any($1)
      and instance_group_id is not null
      and i.state <> 'TERMINATED';
  EOQ

  param "emr_cluster_arns" {}
}
