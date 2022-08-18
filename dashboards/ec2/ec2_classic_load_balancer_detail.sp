dashboard "aws_ec2_classic_load_balancer_detail" {
  title = "AWS EC2 Classic Load balancer Details"
  #documentation = file("./dashboards/lb/docs/clb_relationships.md")

  tags = merge(local.ec2_common_tags, {
    type = "Details"
  })

  input "clb" {
    title = "Select a Classic Load balancer:"
    sql   = query.aws_clb_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_clb_scheme
      args = {
        arn = self.input.clb.value
      }
    }

  }

  container {
    graph {
      type  = "graph"
      title = "Things I use..."
      query = query.aws_clb_graph_relationships
      args = {
        arn = self.input.clb.value
      }

      category "aws_ec2_classic_load_balancer" {
        icon = local.aws_ec2_classic_load_balancer_icon
      }

      category "aws_vpc" {
        href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'VPC ID' | @uri}}"
        icon = local.aws_vpc_icon
      }

      category "aws_s3_bucket" {
        href = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
        icon = local.aws_s3_bucket_icon
      }

      category "aws_vpc_security_group" {
        href = "${dashboard.aws_vpc_security_group_detail.url_path}?input.security_group_id={{.properties.'Group ID' | @uri}}"
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

query "aws_clb_graph_relationships" {
  sql = <<-EOQ
    with clb as (select backend_server_descriptions,scheme,arn,name,account_id,region,title,access_log_s3_bucket_name,access_log_s3_bucket_prefix,security_groups,vpc_id from aws_ec2_classic_load_balancer where arn = $1)
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
        'Scheme', clb.scheme,
        'backend', clb.backend_server_descriptions
      ) as properties
    from
      clb

    -- security groups - nodes
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
      sg.group_id in (select jsonb_array_elements_text(clb.security_groups))

    -- security groups - edges
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
      sg.group_id in (select jsonb_array_elements_text(clb.security_groups))

    -- target groups - nodes
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
      clb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

    -- target groups - edges
    union all
    select
      clb.arn as from_id,
      tg.target_group_arn as to_id,
      null as id,
      'Targets' as title,
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
      clb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

    -- target group instances - nodes
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
      instance.instance_id = thd->'Target'->>'Id'
      and clb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

    -- target group instances - edges
    union all
    select
      tg.target_group_arn as from_id,
      instance.instance_id as to_id,
      null as id,
      'Instance' as title,
      'uses' as category,
      jsonb_build_object(
        'Instance ID', instance.instance_id,
        'ARN', instance.arn,
        'Account ID', instance.account_id,
        'Region', instance.region,
        'Health Check Port', thd['HealthCheckPort'],
        'Health Check State', thd['TargetHealth']['State'],
        'health',tg.target_health_descriptions
      ) as properties
    from
      aws_ec2_target_group tg,
      aws_ec2_instance instance,
      jsonb_array_elements(tg.target_health_descriptions) thd,
      clb
    where
      instance.instance_id = thd->'Target'->>'Id'
      and clb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

    -- S3 bucket I log to - nodes
    union all
    select
      null as from_id,
      null as to_id,
      buckets.arn as id,
      buckets.title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', clb.name,
        'ARN', clb.arn,
        'Account ID', clb.account_id,
        'Region', clb.region,
        'Logs to', clb.access_log_s3_bucket_name
      ) as properties
    from
      aws_s3_bucket buckets,
      clb
    where
      buckets.name = clb.access_log_s3_bucket_name

    -- S3 bucket I log to - edges
    union all
    select
      clb.arn as from_id,
      buckets.arn as to_id,
      null as id,
      'Logs to' as title,
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

    -- vpc - nodes
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

    -- vpc - edges
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

    -- lb listener - nodes
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
        'SSL Policy', COALESCE(lblistener.ssl_policy,'None')
      ) as properties
    from
      aws_ec2_load_balancer_listener lblistener,
      clb
    where
      clb.arn = lblistener.load_balancer_arn

    -- lb listener - edges
    union all
    select
      clb.arn as from_id,
      lblistener.arn as to_id,
      null as id,
      'Listens on' as title,
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

    -- lb listener port - nodes
    union all
    select
      null as from_id,
      null as to_id,
      (lblistener.arn || lblistener.port) as id,
      ('Port ' || lblistener.port) as title,
      'aws_ec2_load_balancer_listener_port' as category,
      jsonb_build_object() as properties
    from
      aws_ec2_load_balancer_listener lblistener,
      clb
    where
      clb.arn = lblistener.load_balancer_arn

    -- lb listener port - edges
    union all
    select
      lblistener.arn as from_id,
      (lblistener.arn || lblistener.port) as to_id,
      null as id,
      'Inbound Port' as title,
      'uses' as category,
      jsonb_build_object() as properties
    from
      aws_ec2_load_balancer_listener lblistener,
      clb
    where
      clb.arn = lblistener.load_balancer_arn

    order by category,from_id,to_id
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
