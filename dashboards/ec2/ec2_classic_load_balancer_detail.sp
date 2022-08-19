dashboard "aws_ec2_classic_load_balancer_detail" {
  title         = "AWS EC2 Classic Load Balancer Details"
  documentation = file("./dashboards/ec2/docs/ec2_classic_load_balancer_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Details"
  })

  input "clb" {
    title = "Select a Classic Load balancer:"
    query = query.aws_clb_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_clb_scheme
      args  = {
        arn = self.input.clb.value
      }
    }

  }

  container {
    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_clb_graph_relationships
      args  = {
        arn = self.input.clb.value
      }
      category "aws_ec2_classic_load_balancer" {
        icon = local.aws_ec2_classic_load_balancer_icon
      }
    }
  }
}

query "aws_clb_scheme" {
  sql = <<-EOQ
    select
      'Schema' as label,
      scheme as value
    from
      aws_ec2_classic_load_balancer
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_clb_relationships_graph" {
  sql = <<-EOQ
    with clb as
    (
      select
        backend_server_descriptions,
        scheme,
        arn,
        name,
        account_id,
        region,
        title,
        access_log_s3_bucket_name,
        access_log_s3_bucket_prefix,
        security_groups,
        vpc_id
      from
        aws_ec2_classic_load_balancer
      where
        arn = $1
    )

    -- Resource (node)
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_ec2_classic_load_balancer' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Security Groups', clb.security_groups,
        'Scheme', clb.scheme
      ) as properties
    from
      clb

    -- To security group (node)
    union all
    select
      null as from_id,
      null as to_id,
      sg.arn as id,
      sg.title as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'Group Name', sg.group_name,
        'Group ID', sg.group_id,
        'ARN', sg.arn,
        'Account ID', sg.account_id,
        'Region', sg.region,
        'VPC ID', sg.vpc_id
      ) as properties
    from
      aws_vpc_security_group sg,
      clb
    where
      sg.group_id in
      (
        select
          jsonb_array_elements_text(clb.security_groups)
      )

    -- To security group (edge)
    union all
    select
      clb.arn as from_id,
      sg.arn as to_id,
      null as id,
      'Security Group' as title,
      'uses' as category,
      jsonb_build_object(
        'Group Name', sg.group_name,
        'Group ID', sg.group_id,
        'ARN', sg.arn,
        'Account ID', sg.account_id,
        'Region', sg.region,
        'VPC ID', sg.vpc_id
      ) as properties
    from
      aws_vpc_security_group sg,
      clb
    where
      sg.group_id in
      (
        select
          jsonb_array_elements_text(clb.security_groups)
      )

    -- To target group (node)
    union all
    select
      null as from_id,
      null as to_id,
      tg.target_group_arn as id,
      tg.title as title,
      'aws_ec2_target_group' as category,
      jsonb_build_object(
        'Group Name', tg.target_group_name,
        'ARN', tg.target_group_arn,
        'Account ID', tg.account_id,
        'Region', tg.region
      ) as properties
    from
      aws_ec2_target_group tg,
      clb
    where
      clb.arn in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      )

    -- To target group (edge)
    union all
    select
      clb.arn as from_id,
      tg.target_group_arn as to_id,
      null as id,
      'targets' as title,
      'uses' as category,
      jsonb_build_object(
        'Group Name', tg.target_group_name,
        'ARN', tg.target_group_arn,
        'Account ID', tg.account_id,
        'Region', tg.region
      ) as properties
    from
      aws_ec2_target_group tg,
      clb
    where
      clb.arn in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      )

    -- To target group instance (node)
    union all
    select
      null as from_id,
      null as to_id,
      instance.instance_id as id,
      instance.title as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'Instance ID', instance.instance_id,
        'ARN', instance.arn,
        'Account ID', instance.account_id,
        'Region', instance.region
      ) as properties
    from
      aws_ec2_target_group tg,
      aws_ec2_instance instance,
      jsonb_array_elements(tg.target_health_descriptions) thd,
      clb
    where
      instance.instance_id = thd -> 'Target' ->> 'Id'
      and clb.arn in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      )

    -- To target group instance (edge)
    union all
    select
      tg.target_group_arn as from_id,
      instance.instance_id as to_id,
      null as id,
      'instance' as title,
      'uses' as category,
      jsonb_build_object(
        'Instance ID', instance.instance_id,
        'ARN', instance.arn,
        'Account ID', instance.account_id,
        'Region', instance.region,
        'Health Check Port', thd['HealthCheckPort'],
        'Health Check State', thd['TargetHealth']['State']
      ) as properties
    from
      aws_ec2_target_group tg,
      aws_ec2_instance instance,
      jsonb_array_elements(tg.target_health_descriptions) thd,
      clb
    where
      instance.instance_id = thd -> 'Target' ->> 'Id'
      and clb.arn in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      )

    -- S3 bucket (node)
    union all
    select
      null as from_id,
      null as to_id,
      buckets.arn as id,
      buckets.title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', buckets.name,
        'ARN', buckets.arn,
        'Account ID', buckets.account_id,
        'Region', buckets.region,
        'Logs to', clb.access_log_s3_bucket_name
      ) as properties
    from
      aws_s3_bucket buckets,
      clb
    where
      buckets.name = clb.access_log_s3_bucket_name

    -- S3 bucket (edge)
    union all
    select
      clb.arn as from_id,
      buckets.arn as to_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', clb.name,
        'ARN', clb.arn,
        'Account ID', clb.account_id,
        'Region', clb.region,
        'Logs to', clb.access_log_s3_bucket_name,
        'Log Prefix', clb.access_log_s3_bucket_prefix
      ) as properties
    from
      aws_s3_bucket buckets,
      clb
    where
      buckets.name = clb.access_log_s3_bucket_name

    -- VPC (node)
    union all
    select
      null as from_id,
      null as to_id,
      vpc.vpc_id as id,
      vpc.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'VPC ID', vpc.vpc_id,
        'Account ID', vpc.account_id,
        'Region', vpc.region,
        'CIDR Block', vpc.cidr_block
      ) as properties
    from
      aws_vpc vpc,
      clb
    where
      clb.vpc_id = vpc.vpc_id

    -- VPC (edges)
    union all
    select
      clb.arn as from_id,
      vpc.vpc_id as to_id,
      null as id,
      'VPC' as title,
      'uses' as category,
      jsonb_build_object(
        'VPC ID', vpc.vpc_id,
        'Account ID', vpc.account_id,
        'Region', vpc.region,
        'CIDR Block', vpc.cidr_block
      ) as properties
    from
      aws_vpc vpc,
      clb
    where
      clb.vpc_id = vpc.vpc_id

    -- To EC2 load balancer listener (node)
    union all
    select
      null as from_id,
      null as to_id,
      lblistener.arn as id,
      lblistener.title as title,
      'aws_ec2_load_balancer_listener' as category,
      jsonb_build_object(
        'ARN', lblistener.arn,
        'Account ID', lblistener.account_id,
        'Region', lblistener.region,
        'Protocol', lblistener.protocol,
        'Port', lblistener.port,
        'SSL Policy', coalesce(lblistener.ssl_policy, 'None')
      ) as properties
    from
      aws_ec2_load_balancer_listener lblistener,
      clb
    where
      clb.arn = lblistener.load_balancer_arn

    -- To EC2 load balancer listener (edge)
    union all
    select
      clb.arn as from_id,
      lblistener.arn as to_id,
      null as id,
      'listens on' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', lblistener.arn,
        'Account ID', lblistener.account_id,
        'Region', lblistener.region
      ) as properties
    from
      aws_ec2_load_balancer_listener lblistener,
      clb
    where
      clb.arn = lblistener.load_balancer_arn

    -- To EC2 load balancer listener port (node)
    union all
    select
      null as from_id,
      null as to_id,
      (
        lblistener.arn || lblistener.port
      )
      as id,
      (
        'Port ' || lblistener.port
      )
      as title,
      'aws_ec2_load_balancer_listener_port' as category,
      jsonb_build_object() as properties
    from
      aws_ec2_load_balancer_listener lblistener,
      clb
    where
      clb.arn = lblistener.load_balancer_arn

    -- To EC2 load balancer listener port (edge)
    union all
    select
      lblistener.arn as from_id,
      (
        lblistener.arn || lblistener.port
      )
      as to_id,
      null as id,
      'inbound port' as title,
      'uses' as category,
      jsonb_build_object() as properties
    from
      aws_ec2_load_balancer_listener lblistener,
      clb
    where
      clb.arn = lblistener.load_balancer_arn

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}

query "aws_clb_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_ec2_classic_load_balancer
    order by
      title;
  EOQ
}
