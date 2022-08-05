dashboard "aws_alb_relationships" {
  title         = "AWS EC2 Application Loadbalancer Relationships"
  #documentation = file("./dashboards/lb/docs/alb_relationships.md")
  
  tags = merge(local.ec2_common_tags, {
    type = "Relationships"
  })
  
  input "alb" {
    title = "Select an Application Loadbalancer:"
    sql   = query.aws_alb_input.sql
    width = 4
  }
  
  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_alb_graph_to_instance
    args = {
      arn = self.input.alb.value
    }
    
    category "aws_ec2_application_load_balancer" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/alb.svg"))
    }

    category "aws_vpc" {
      href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'VPC ID' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/vpc.svg"))
    }

    category "aws_s3_bucket" {
      href = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/alb.svg"))
    }
    
  }

}


query "aws_alb_graph_to_instance"{
  sql = <<-EOQ
    with alb as (select arn,name,account_id,region,title,security_groups,vpc_id,load_balancer_attributes from aws_ec2_application_load_balancer where arn = $1)
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
        'Security Groups', alb.security_groups
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
      'uses' as title,
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
      'Logs to' as title,
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
      'uses' as title,
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