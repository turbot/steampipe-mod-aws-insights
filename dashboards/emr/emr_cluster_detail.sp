dashboard "aws_emr_cluster_detail" {
  title         = "AWS EMR Cluster Detail"
  documentation = file("./dashboards/emr/docs/emr_cluster_detail.md")

  tags = merge(local.emr_common_tags, {
    type = "Detail"
  })

  input "emr_cluster_arn" {
    title = "Select a cluster:"
    query = query.aws_emr_cluster_input
    width = 4
  }

  graph {
    type  = "graph"
    title = "Relationships"
    query = query.aws_emr_cluster_relationships_graph
    args = {
      arn = self.input.emr_cluster_arn.value
    }
    category "aws_emr_cluster" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/emr_cluster_light.svg"))
    }

    category "aws_iam_role" {
      href = "${dashboard.aws_iam_role_detail.url_path}?input.role_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/iam_role_light.svg"))
    }

    category "aws_s3_bucket" {
      href = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/s3_bucket_light.svg"))
    }

    category "aws_ec2_ami" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_ami_light.svg"))
    }

    category "uses" {
      color = "green"
    }
  }
}

query "aws_emr_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      cluster_arn as value,
      json_build_object(
        'id', id,
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_emr_cluster
    order by
      title;
EOQ
}

query "aws_emr_cluster_relationships_graph" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      id as id,
      title as title,
      'aws_emr_cluster' as category,
      jsonb_build_object( 'ARN', cluster_arn, 'State', state, 'Log URI', log_uri, 'Auto Terminate', auto_terminate::text, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_emr_cluster
    where
      cluster_arn = $1

    -- To IAM Roles (node)
    union all
    select
      null as from_id,
      null as to_id,
      role_id as id,
      title as title,
      'aws_iam_role' as category,
      jsonb_build_object( 'ARN', arn, 'Create Date', create_date, 'Max Session Duration', max_session_duration, 'Account ID', account_id ) as properties
    from
      aws_iam_role
    where
      name in
      (
        select
          service_role
        from
          aws_emr_cluster
        where
          cluster_arn = $1
      )

    -- To IAM Roles (edge)
    union all
    select
      c.id as from_id,
      role_id as to_id,
      null as id,
      'associated to' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_iam_role as r,
      aws_emr_cluster as c
    where
      c.cluster_arn = $1
      and r.name = c.service_role

    -- To S3 buckets (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object( 'Name', name, 'ARN', arn, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_s3_bucket
    where
      name in
      (
        select
          split_part(log_uri, '/', 3)
        from
          aws_emr_cluster
        where
          cluster_arn = $1
      )

    -- To S3 Buckets (edge)
    union all
    select
      c.id as from_id,
      b.arn as to_id,
      null as id,
      'Logs to' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_emr_cluster as c
      left join
        aws_s3_bucket as b
        on split_part(log_uri, '/', 3) = b.name
    where
      cluster_arn = $1

    -- To EMR instance groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      id as id,
      title as title,
      'aws_emr_instance_group' as category,
      jsonb_build_object( 'ARN', arn, 'State', state, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_emr_instance_group
    where
      cluster_id in
      (
        select
          id
        from
          aws_emr_cluster
        where
          cluster_arn = $1
      )

    -- To EMR instance groups (edge)
    union all
    select
      c.id as from_id,
      g.id as to_id,
      null as id,
      'contains' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_emr_cluster as c
      left join
        aws_emr_instance_group as g
        on g.cluster_id = c.id
    where
      cluster_arn = $1


    -- To EC2 AMIs (node)
    union all
    select
      null as from_id,
      null as to_id,
      image_id as id,
      title as title,
      'aws_ec2_ami' as category,
      jsonb_build_object( 'Image ID', image_id, 'Creation Date', creation_date, 'State', state, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_ec2_ami
    where
      image_id in
      (
        select
          custom_ami_id
        from
          aws_emr_cluster
        where
          cluster_arn = $1
      )

     -- To EC2 AMIs (edge)
    union all
    select
      c.id as from_id,
      image_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', c.account_id ) as properties
    from
      aws_emr_cluster as c
      left join
        aws_ec2_ami as a
        on a.image_id = c.custom_ami_id
    where
      cluster_arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}
