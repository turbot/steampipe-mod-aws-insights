dashboard "aws_ec2_gateway_load_balancer_detail" {
  title         = "AWS EC2 Gateway Load Balancer Detail"
  documentation = file("./dashboards/ec2/docs/ec2_gateway_load_balancer_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "glb" {
    title = "Select a Gateway Load balancer:"
    query = query.aws_glb_input
    width = 4
  }
  container {

    card {
      width = 2
      query = query.aws_glb_state
      args = {
        arn = self.input.glb.value
      }
    }

    card {
      width = 2
      query = query.aws_glb_scheme
      args = {
        arn = self.input.glb.value
      }
    }
    
    card {
      width = 2
      query = query.aws_glb_ip_type
      args = {
        arn = self.input.glb.value
      }
    }

    card {
      width = 2
      query = query.aws_glb_az_zone
      args = {
        arn = self.input.glb.value
      }
    }

    card {
      width = 2
      query = query.aws_glb_deletion_protection
      args = {
        arn = self.input.glb.value
      }
    }

  }

  container {
    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_ec2_gateway_load_balancer_relationships_graph
      args = {
        arn = self.input.glb.value
      }
    }

  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.aws_ec2_glb_overview
      args = {
        arn = self.input.glb.value
      }

    }

    table {
      title = "Tags"
      width = 3
      query = query.aws_ec2_glb_tags
      args = {
        arn = self.input.glb.value
      }
    }

    table {
      title = "Attributes"
      width = 4
      query = query.aws_ec2_glb_attributes
      args = {
        arn = self.input.glb.value
      }
    }

    table {
      title = "Security Groups"
      width = 2
      query = query.aws_ec2_glb_security_groups
      args = {
        arn = self.input.glb.value
      }
    }
  }

}

query "aws_ec2_glb_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      dns_name as "DNS Name",
      canonical_hosted_zone_id as "Route 53 hosted zone ID",
      account_id as "Account ID",
      region as "Region",
      partition as "Partition"
    from
      aws_ec2_gateway_load_balancer
    where
      aws_ec2_gateway_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_glb_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ec2_gateway_load_balancer,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}

query "aws_ec2_glb_attributes" {
  sql = <<-EOQ
    select
      lb ->> 'Key' as "Key",
      lb ->> 'Value' as "Value"
    from
      aws_ec2_gateway_load_balancer
      cross join jsonb_array_elements(load_balancer_attributes) as lb
    where
      aws_ec2_gateway_load_balancer.arn = $1
      and lb ->> 'Key' not in ( 'deletion_protection.enabled' ,'access_logs.s3.enabled' )
    order by
      lb ->> 'Key';
    EOQ

  param "arn" {}
}

query "aws_ec2_glb_security_groups" {
  sql = <<-EOQ
    select
      sg as "Groups"
    from
      aws_ec2_gateway_load_balancer,
      jsonb_array_elements_text(aws_ec2_gateway_load_balancer.security_groups) as sg
    where
      aws_ec2_gateway_load_balancer.arn = $1;
    EOQ

  param "arn" {}
}

query "aws_glb_ip_type" {
  sql = <<-EOQ
    select
      'IP Address type' as label,
      case when ip_address_type = 'ipv4' then 'IPv4' else 'IPv6' end as value
    from
      aws_ec2_gateway_load_balancer
    where
      aws_ec2_gateway_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_glb_logging_enabled" {
  sql = <<-EOQ
    select
      'Logging' as label,
      case when lb ->> 'Value' = 'false' then 'Disabled' else 'Enabled' end as value,
      case when lb ->> 'Value' = 'false' then 'alert' else 'ok' end as type
    from
      aws_ec2_gateway_load_balancer
      cross join jsonb_array_elements(load_balancer_attributes) as lb
    where
      lb ->> 'Key' = 'access_logs.s3.enabled'
      and aws_ec2_gateway_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_glb_deletion_protection" {
  sql = <<-EOQ
    select
      'Deletion Protection' as label,
      case when lb ->> 'Value' = 'false' then 'Disabled' else 'Enabled' end as value,
      case when lb ->> 'Value' = 'false' then 'alert' else 'ok' end as type
    from
      aws_ec2_gateway_load_balancer
      cross join jsonb_array_elements(load_balancer_attributes) as lb
    where
      lb ->> 'Key' = 'deletion_protection.enabled'
      and aws_ec2_gateway_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_glb_az_zone" {
  sql = <<-EOQ
    select
      'Availibility Zones' as label,
      count(az ->> 'ZoneName') as value,
      case when count(az ->> 'ZoneName') > 1 then 'ok' else 'alert' end as type
    from
      aws_ec2_gateway_load_balancer
      cross join jsonb_array_elements(availability_zones) as az
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_glb_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(state_code) as value
    from
      aws_ec2_gateway_load_balancer
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_glb_scheme" {
  sql = <<-EOQ
    select
      'Scheme' as label,
      initcap(scheme) as value
    from
      aws_ec2_gateway_load_balancer
    where
      arn = $1;
  EOQ

  param "arn" {}
}


query "aws_ec2_gateway_load_balancer_relationships_graph" {
  sql = <<-EOQ
    with glb as
    (
      select
        arn,
        name,
        account_id,
        region,
        title,
        security_groups,
        vpc_id,
        load_balancer_attributes
      from
        aws_ec2_gateway_load_balancer
      where
        arn = $1
    )

    -- Resource (node)
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

    -- To VPC security groups (node)
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
      sg.group_id in
      (
        select
          jsonb_array_elements_text(glb.security_groups)
      )

    -- To VPC security groups (edge)
    union all
    select
      glb.arn as from_id,
      sg.arn as to_id,
      null as id,
      'Security Group' as title,
      'ec2_gateway_load_balancer_to_vpc_security_group' as category,
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
      sg.group_id in
      (
        select
          jsonb_array_elements_text(glb.security_groups)
      )

    -- To target groups (node)
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
      glb.arn in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      )

    -- To target groups (edge)
    union all
    select
      glb.arn as from_id,
      tg.target_group_arn as to_id,
      null as id,
      'targets' as title,
      'ec2_gateway_load_balancer_to_ec2_target_group' as category,
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
      glb.arn in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      )

    -- To EC2 target group instances (node)
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
      instance.instance_id = thd -> 'Target' ->> 'Id'
      and glb.arn in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      )

    -- To EC2 target group instances (edge)
    union all
    select
      tg.target_group_arn as from_id,
      instance.instance_id as to_id,
      null as id,
      'forwards to' as title,
      'ec2_target_group_to_ec2_instance' as category,
      jsonb_build_object(
        'Instance ID', instance.instance_id,
        'ARN', instance.arn,
        'Account ID', instance.account_id,
        'Region', instance.region,
        'Health Check Port', thd['HealthCheckPort'],
        'Health Check State', thd['TargetHealth']['State'],
        'health', tg.target_health_descriptions
      ) as properties
    from
      aws_ec2_target_group tg,
      aws_ec2_instance instance,
      jsonb_array_elements(tg.target_health_descriptions) thd,
      glb
    where
      instance.instance_id = thd -> 'Target' ->> 'Id'
      and glb.arn in
      (
        select
          jsonb_array_elements_text(tg.load_balancer_arns)
      )

    -- To S3 buckets (node)
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
        'Account ID', glb.account_id,
        'Region', glb.region,
        'Logs to', attributes->>'Value'
      ) as properties
    from
      aws_s3_bucket buckets,
      glb,
      jsonb_array_elements(glb.load_balancer_attributes) attributes
    where
      attributes ->> 'Key' = 'access_logs.s3.bucket'
      and buckets.name = attributes ->> 'Value'

    -- To S3 buckets (edge)
    union all
    select
      glb.arn as from_id,
      buckets.arn as to_id,
      null as id,
      'logs to' as title,
      'ec2_gateway_load_balancer_to_s3_bucket' as category,
      jsonb_build_object(
        'Name', glb.name,
        'ARN', glb.arn,
        'Account ID', glb.account_id,
        'Region', glb.region,
        'Logs to', attributes ->> 'Value'
      ) as properties
    from
      aws_s3_bucket buckets,
      glb,
      jsonb_array_elements(glb.load_balancer_attributes) attributes
    where
      attributes ->> 'Key' = 'access_logs.s3.bucket'
      and buckets.name = attributes ->> 'Value'

    -- VPCs (node)
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

    -- VPCs (edge)
    union all
    select
      glb.arn as from_id,
      vpc.vpc_id as to_id,
      null as id,
      'resides in' as title,
      'ec2_gateway_load_balancer_to_vpc' as category,
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

    -- To load balancer listeners (node)
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
      glb
    where
      glb.arn = lblistener.load_balancer_arn

    -- To load balancer listeners (edge)
    union all
    select
      lblistener.arn as from_id,
      glb.arn as to_id,
      null as id,
      'listens with' as title,
      'load_balancer_listener_to_ec2_gateway_load_balancer' as category,
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

    order by
      category,
      from_id,
      to_id;
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
