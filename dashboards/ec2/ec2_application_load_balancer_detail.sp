dashboard "aws_ec2_application_load_balancer_detail" {
  title = "AWS EC2 Application Load balancer Detail"
  #documentation = file("./dashboards/lb/docs/alb_relationships.md")

  tags = merge(local.ec2_common_tags, {
    type = "Details"
  })

  input "alb" {
    title = "Select an Application Load balancer:"
    query = query.aws_alb_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_alb_scheme
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.aws_alb_ports
      args = {
        arn = self.input.alb.value
      }
    }

  }

  container {
    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_alb_graph_relationships
      args = {
        arn = self.input.alb.value
      }
      category "aws_ec2_application_load_balancer" {
        icon = local.aws_ec2_application_load_balancer_icon
      }

    }
  }
}

query "aws_alb_ports" {
  sql = <<-EOQ
    with d as (select distinct(port) as port from aws_ec2_load_balancer_listener where load_balancer_arn = $1)
    select
      'Ports' as label,
      string_agg(port::text, ',') as value
    from
      d
  EOQ

  param "arn" {}
}

query "aws_alb_scheme" {
  sql = <<-EOQ
    select
      'Schema' as label,
      scheme as value
    from
      aws_ec2_application_load_balancer
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_alb_graph_relationships" {
  sql = <<-EOQ
    with alb as (select dns_name,arn,name,account_id,region,title,security_groups,vpc_id,load_balancer_attributes from aws_ec2_application_load_balancer where arn = $1)
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_ec2_application_load_balancer' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'DNS Name', alb.dns_name
      ) as properties
    from
      alb

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
      alb
    where
      sg.group_id in (select jsonb_array_elements_text(alb.security_groups))

    -- security groups - edges
    union all
    select
      alb.arn as from_id,
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
      alb
    where
      sg.group_id in (select jsonb_array_elements_text(alb.security_groups))

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
      alb
    where
      alb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

    -- target groups - edges
    union all
    select
      alb.arn as from_id,
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
      alb
    where
      alb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

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
      alb
    where
      instance.instance_id = thd->'Target'->>'Id'
      and alb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

    -- target group instances - edges
    union all
    select
      tg.target_group_arn as from_id,
      instance.instance_id as to_id,
      null as id,
      'forwards to' as title,
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
      alb
    where
      instance.instance_id = thd->'Target'->>'Id'
      and alb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

    -- S3 bucket I log to - nodes
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
        'Account ID', alb.account_id,
        'Region', alb.region,
        'Logs to', attributes->>'Value'
      ) as properties
    from
      aws_s3_bucket buckets,
      alb,
      jsonb_array_elements(alb.load_balancer_attributes) attributes
    where
      attributes->>'Key' = 'access_logs.s3.bucket'
      and buckets.name = attributes->>'Value'

    -- S3 bucket I log to - edges
    union all
    select
      alb.arn as from_id,
      buckets.arn as to_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', buckets.name,
        'ARN', buckets.arn,
        'Account ID', alb.account_id,
        'Region', alb.region,
        'Logs to', attributes->>'Value',
        'Log Prefix', (select a->>'Value' from jsonb_array_elements(alb.load_balancer_attributes) as a where a->>'Key' = 'access_logs.s3.prefix' )
      ) as properties
    from
      aws_s3_bucket buckets,
      alb,
      jsonb_array_elements(alb.load_balancer_attributes) attributes
    where
      attributes->>'Key' = 'access_logs.s3.bucket'
      and buckets.name = attributes->>'Value'

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
      alb
    where
      alb.vpc_id = vpc.vpc_id

    -- vpc - edges
    union all
    select
      alb.arn as from_id,
      vpc.vpc_id as to_id,
      null as id,
      'resides in' as title,
      'uses' as category,
      jsonb_build_object(
        'VPC ID', vpc.vpc_id,
        'Account ID', vpc.account_id,
        'Region', vpc.region,
        'CIDR Block', vpc.cidr_block
      ) as properties
    from
      aws_vpc vpc,
      alb
    where
      alb.vpc_id = vpc.vpc_id

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
      alb
    where
      alb.arn = lblistener.load_balancer_arn

    -- lb listener - edges
    union all
    select
      alb.arn as from_id,
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
      alb
    where
      alb.arn = lblistener.load_balancer_arn

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
      alb
    where
      alb.arn = lblistener.load_balancer_arn

    -- lb listener port - edges
    union all
    select
      lblistener.arn as from_id,
      (lblistener.arn || lblistener.port) as to_id,
      null as id,
      'through port' as title,
      'uses' as category,
      jsonb_build_object() as properties
    from
      aws_ec2_load_balancer_listener lblistener,
      alb
    where
      alb.arn = lblistener.load_balancer_arn

    order by category,from_id,to_id

  EOQ

  param "arn" {}
}

query "aws_alb_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_ec2_application_load_balancer
    order by
      title;
  EOQ
}
