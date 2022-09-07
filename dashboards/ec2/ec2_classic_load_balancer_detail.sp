dashboard "aws_ec2_classic_load_balancer_detail" {
  title         = "AWS EC2 Classic Load Balancer Detail"
  documentation = file("./dashboards/ec2/docs/ec2_classic_load_balancer_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
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
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.aws_clb_instances
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.aws_clb_logging_enabled
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.aws_clb_az_zone
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.aws_clb_cross_zone_enabled
      args = {
        arn = self.input.clb.value
      }
    }

  }

  container {
    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_ec2_classic_load_balancer_relationships_graph
      args = {
        arn = self.input.clb.value
      }
      category "aws_ec2_classic_load_balancer" {
        icon = local.aws_ec2_classic_load_balancer_icon
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.aws_ec2_clb_overview
      args = {
        arn = self.input.clb.value
      }

    }

    table {
      title = "Tags"
      width = 3
      query = query.aws_ec2_clb_tags
      args = {
        arn = self.input.clb.value
      }
    }
  }

}
query "aws_ec2_clb_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      created_time as "Created Time",
      dns_name as "DNS Name",
      canonical_hosted_zone_name_id as "Route 53 Hosted Zone ID",
      account_id as "Account ID",
      region as "Region",
      arn as "ARN"
    from
      aws_ec2_classic_load_balancer
    where
      aws_ec2_classic_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_clb_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ec2_classic_load_balancer,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}

query "aws_clb_logging_enabled" {
  sql = <<-EOQ
    select
      'Logging' as label,
      case when access_log_enabled = 'false' then 'Disabled' else 'Enabled' end as value,
      case when access_log_enabled = 'false' then 'alert' else 'ok' end as type
    from
      aws_ec2_classic_load_balancer
    where
      aws_ec2_classic_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_clb_az_zone" {
  sql = <<-EOQ
    select
      'Availibility Zones' as label,
      count(az ->> 'ZoneName') as value,
      case when count(az ->> 'ZoneName') > 1 then 'ok' else 'alert' end as type
    from
      aws_ec2_classic_load_balancer
      cross join jsonb_array_elements(availability_zones) as az
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_clb_cross_zone_enabled" {
  sql = <<-EOQ
    select
      'Cross Zone' as label,
      case when cross_zone_load_balancing_enabled then 'Enabled' else 'Disabled' end as value,
      case when cross_zone_load_balancing_enabled then 'ok' else 'alert' end as type
    from
      aws_ec2_classic_load_balancer
      cross join jsonb_array_elements(availability_zones) as az
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_clb_instances" {
  sql = <<-EOQ
    select
      'Instances' as label,
      count(i) as value,
      case when count(i) >= 1 then 'ok' else 'alert' end as type
    from
      aws_ec2_classic_load_balancer
      cross join jsonb_array_elements(instances) as i
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_clb_scheme" {
  sql = <<-EOQ
    select
      'Scheme' as label,
      initcap(scheme) as value
    from
      aws_ec2_classic_load_balancer
    where
      arn = $1;
  EOQ

  param "arn" {}
}


query "aws_ec2_classic_load_balancer_relationships_graph" {
  sql = <<-EOQ
    with clb as
    (
      select
        access_log_s3_bucket_prefix,
        access_log_s3_bucket_name,
        account_id,
        arn,
        instances,
        name,
        region,
        scheme,
        security_groups,
        title,
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

    -- To EC2 Instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      instances.arn as id,
      instances.title as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'Instance ID', instances.instance_id,
        'ARN', instances.arn,
        'Account ID', instances.account_id,
        'Region', instances.region
      ) as properties
    from
      clb
      cross join jsonb_array_elements(clb.instances) as i
    left join
      aws_ec2_instance instances
      on instances.instance_id = i ->> 'InstanceId'

    -- To EC2 Instances (edge)
    union all
    select
      clb.arn as from_id,
      instances.arn as to_id,
      null as id,
      'ec2 instance' as title,
      'ec2_classic_load_balancer_to_ec2_instance' as category,
      jsonb_build_object(
        'Account ID', instances.account_id
      ) as properties
    from
      clb
      cross join jsonb_array_elements(clb.instances) as i
    left join
      aws_ec2_instance instances
      on instances.instance_id = i ->> 'InstanceId'

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
        'Account ID', buckets.account_id,
        'Region', buckets.region,
        'Logs to', clb.access_log_s3_bucket_name
      ) as properties
    from
      aws_s3_bucket buckets,
      clb
    where
      buckets.name = clb.access_log_s3_bucket_name

    -- To S3 buckets (edge)
    union all
    select
      clb.arn as from_id,
      buckets.arn as to_id,
      null as id,
      'logs to' as title,
      'ec2_classic_load_balancer_to_s3_bucket' as category,
      jsonb_build_object(
        'Account ID', buckets.account_id,
        'Log Prefix', clb.access_log_s3_bucket_prefix
      ) as properties
    from
      aws_s3_bucket buckets,
      clb
    where
      buckets.name = clb.access_log_s3_bucket_name

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
      clb
    where
      sg.group_id in
      (
        select
          jsonb_array_elements_text(clb.security_groups)
      )

    -- To VPC security groups (edge)
    union all
    select
      clb.arn as from_id,
      sg.arn as to_id,
      null as id,
      'security group' as title,
      'ec2_classic_load_balancer_to_vpc_secutiry_group' as category,
      jsonb_build_object(
        'Account ID', sg.account_id
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

    -- To VPCs (node)
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

    -- To VPCs (edges)
    union all
    select
      sg.arn as from_id,
      vpc.vpc_id as to_id,
      null as id,
      'vpc' as title,
      'ec2_classic_load_balancer_to_vpc' as category,
      jsonb_build_object(
        'Account ID', vpc.account_id
      ) as properties
    from
      aws_vpc vpc,
      clb
    left join aws_vpc_security_group sg on sg.group_id in (select jsonb_array_elements_text(clb.security_groups))
    where
      clb.vpc_id = vpc.vpc_id

    -- To EC2 load balancer listeners (node)
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

    -- To EC2 load balancer listeners (edge)
    union all
    select
      lblistener.arn as from_id,
      clb.arn as to_id,
      null as id,
      'listens with' as title,
      'load_balancer_listener_to_ec2_classic_load_balancer' as category,
      jsonb_build_object(
        'Account ID', lblistener.account_id
      ) as properties
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
