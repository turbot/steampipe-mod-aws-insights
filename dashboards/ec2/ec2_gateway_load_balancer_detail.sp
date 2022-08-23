dashboard "aws_ec2_gateway_load_balancer_detail" {
  title = "AWS EC2 Gateway Load balancer Detail"
  #documentation = file("./dashboards/lb/docs/glb_relationships.md")

  tags = merge(local.ec2_common_tags, {
    type = "Details"
  })

  input "glb" {
    title = "Select a Gateway Load balancer:"
    query = query.aws_glb_input
    width = 4
  }

  container {
    graph {
      type  = "graph"
      title = "Things I use..."
      query = query.aws_glb_graph_relationships
      args = {
        arn = self.input.glb.value
      }

      category "aws_ec2_gateway_load_balancer" {
        icon = local.aws_ec2_gateway_load_balancer_icon
      }

      category "aws_vpc" {
        href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'VPC ID' | @uri}}"
        icon = local.aws_vpc_icon
      }

      category "aws_s3_bucket" {
        href = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
        icon = local.aws_s3_bucket_icon
      }

    }

  }

}


query "aws_glb_graph_relationships" {
  sql = <<-EOQ
    with glb as (select arn,name,account_id,region,title,security_groups,vpc_id,load_balancer_attributes from aws_ec2_gateway_load_balancer where arn = $1)
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_ec2_gateway_load_balancer' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Security Groups', glb.security_groups
      ) as properties
    from
      glb

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
      glb
    where
      sg.group_id in (select jsonb_array_elements_text(glb.security_groups))

    -- security groups - edges
    union all
    select
      glb.arn as from_id,
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
      glb
    where
      sg.group_id in (select jsonb_array_elements_text(glb.security_groups))

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
      glb
    where
      glb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

    -- target groups - edges
    union all
    select
      glb.arn as from_id,
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
      glb
    where
      glb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

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
      glb
    where
      instance.instance_id = thd->'Target'->>'Id'
      and glb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

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
      glb
    where
      instance.instance_id = thd->'Target'->>'Id'
      and glb.arn in (select jsonb_array_elements_text(tg.load_balancer_arns))

    -- S3 bucket I log to - nodes
    union all
    select
      null as from_id,
      null as to_id,
      buckets.arn as id,
      buckets.title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', glb.name,
        'ARN', glb.arn,
        'Account ID', glb.account_id,
        'Region', glb.region,
        'Logs to', attributes->>'Value'
      ) as properties
    from
      aws_s3_bucket buckets,
      glb,
      jsonb_array_elements(glb.load_balancer_attributes) attributes
    where
      attributes->>'Key' = 'access_logs.s3.bucket'
      and buckets.name = attributes->>'Value'

    -- S3 bucket I log to - edges
    union all
    select
      glb.arn as from_id,
      buckets.arn as to_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', glb.name,
        'ARN', glb.arn,
        'Account ID', glb.account_id,
        'Region', glb.region,
        'Logs to', attributes->>'Value'
      ) as properties
    from
      aws_s3_bucket buckets,
      glb,
      jsonb_array_elements(glb.load_balancer_attributes) attributes
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
      glb
    where
      glb.vpc_id = vpc.vpc_id

    -- vpc - edges
    union all
    select
      glb.arn as from_id,
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
      glb
    where
      glb.vpc_id = vpc.vpc_id

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
      glb
    where
      glb.arn = lblistener.load_balancer_arn

    -- lb listener - edges
    union all
    select
      glb.arn as from_id,
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
      glb
    where
      glb.arn = lblistener.load_balancer_arn

    order by category,from_id,to_id
  EOQ

  param "arn" {}
}

query "aws_glb_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_ec2_gateway_load_balancer
    order by
      title;
  EOQ
}
