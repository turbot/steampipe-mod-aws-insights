node "emr_cluster" {
  category = category.emr_cluster

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ARN', cluster_arn,
        'State', state,
        'Log URI', log_uri,
        'Auto Terminate', auto_terminate::text,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_emr_cluster
    where
      cluster_arn = any($1);
  EOQ

  param "emr_cluster_arns" {}
}

node "emr_instance" {
  category = category.emr_instance

  sql = <<-EOQ
    select
      emri.id as id,
      emri.title as title,
      jsonb_build_object(
        'EC2 Instance ARN', ec2i.arn,
        'EC2 Instance ID', ec2_instance_id,
        'State', emri.state,
        'Instance Type', emri.instance_type,
        'Account ID', emri.account_id,
        'Region', emri.region ) as properties
    from
      aws_ec2_instance as ec2i,
      aws_emr_cluster as c,
      aws_emr_instance as emri
    where
      ec2i.instance_id = emri.ec2_instance_id
      and cluster_id = c.id
      and c.cluster_arn = any($1);
  EOQ

  param "emr_cluster_arns" {}
}      

node "emr_instance_fleet" {
  category = category.emr_instance_fleet

  sql = <<-EOQ
    select
      f.id as id,
      f.title as title,
      jsonb_build_object(
        'ARN', f.arn,
        'State', f.state,
        'Account ID', f.account_id,
        'Region', f.region ) as properties
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

node "emr_instance_group" {
  category = category.emr_instance_group

  sql = <<-EOQ
    select
      g.id as id,
      g.title as title,
      jsonb_build_object(
        'ARN', g.arn,
        'State', g.state,
        'Account ID', g.account_id,
        'Region', g.region ) as properties
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