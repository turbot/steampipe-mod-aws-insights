dashboard "aws_vpc_flow_log_detail" {

  title         = "AWS VPC Flow Log Detail"
  documentation = file("./dashboards/vpc/docs/vpc_flow_log_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "flow_log_id" {
    title = "Select a flow log:"
    query = query.aws_vpc_flow_log_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_vpc_flow_log_resource_id
      args = {
        flow_log_id = self.input.flow_log_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_flow_log_deliver_logs_status
      args = {
        flow_log_id = self.input.flow_log_id.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_vpc_flow_log_relationships_graph
      args = {
        flow_log_id = self.input.flow_log_id.value
      }
      category "aws_vpc_flow_log" {
        icon = local.aws_vpc_flow_log_icon
      }

    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_vpc_flow_log_overview
        args = {
          flow_log_id = self.input.flow_log_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_vpc_flow_tags
        args = {
          flow_log_id = self.input.flow_log_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Log Destination"
        width = 12
        query = query.aws_vpc_flow_log_destination
        args = {
          flow_log_id = self.input.flow_log_id.value
        }

        column "Bucket" {
          href = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.'Bucket' | @uri}}"

        }
      }

    }

  }

}

query "aws_vpc_flow_log_input" {
  sql = <<-EOQ
    select
      title as label,
      flow_log_id as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_vpc_flow_log
    order by
      title;
  EOQ

}

query "aws_vpc_flow_log_resource_id" {
  sql = <<-EOQ
    select
      'Resource ID' as label,
      resource_id as value
    from
      aws_vpc_flow_log
    where
      flow_log_id = $1
  EOQ

  param "flow_log_id" {}
}

query "aws_vpc_flow_log_deliver_logs_status" {
  sql = <<-EOQ
    select
      'Deliver Logs Status' as label,
      deliver_logs_status as value,
      case when deliver_logs_status = 'SUCCESS' then 'ok' else 'alert' end as type
    from
      aws_vpc_flow_log
    where
      flow_log_id = $1
  EOQ

  param "flow_log_id" {}
}

query "aws_vpc_flow_log_relationships_graph" {
  sql = <<-EOQ
    with flow_log as (
      select
        *
      from
        aws_vpc_flow_log
      where
        flow_log_id = $1
    )
    select
      null as from_id,
      null as to_id,
      flow_log_id as id,
      title as title,
      'aws_vpc_flow_log' as category,
      jsonb_build_object(
        'Status', flow_log_status,
        'Creation Time', creation_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      flow_log

    -- To S3 buckets (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.arn as id,
      s.title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'ARN', s.arn,
        'Region', s.region,
        'Account ID', s.account_id
      ) as properties
    from
      flow_log as f
      left join aws_s3_bucket as s on f.bucket_name = s.name
    where
      f.log_destination_type = 's3'

    -- To S3 buckets (edge)
    union all
    select
      f.flow_log_id as from_id,
      s.arn as to_id,
      null as id,
      'logs to' as title,
      'vpc_flow_log_to_s3_bucket' as category,
      jsonb_build_object(
        'ARN', s.arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      flow_log as f
      left join aws_s3_bucket as s on f.bucket_name = s.name
    where
      f.log_destination_type = 's3'

    -- To CloudWatch log groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      c.arn as id,
      c.title as title,
      'aws_cloudwatch_log_group' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Region', c.region,
        'Account ID', c.account_id
      ) as properties
    from
      flow_log as f
      left join aws_cloudwatch_log_group as c on f.log_group_name = c.name
    where
      f.log_destination_type = 'cloud-watch-logs'
      and f.region = c.region

    -- To Cloudwatch log groups (edge)
    union all
    select
      f.flow_log_id as from_id,
      c.arn as to_id,
      null as id,
      'logs to' as title,
      'vpc_flow_log_to_cloudwatch_log_group' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      flow_log as f
      left join aws_cloudwatch_log_group as c on f.log_group_name = c.name
    where
      f.log_destination_type = 'cloud-watch-logs'
      and f.region = c.region

    -- To IAM roles (node)
    union all
    select
      null as from_id,
      null as to_id,
      r.arn as id,
      r.title as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Account ID', r.account_id
      ) as properties
    from
      flow_log as f
      left join aws_iam_role as r on f.deliver_logs_permission_arn = r.arn

    -- To IAM roles (edge)
    union all
    select
      f.flow_log_id as from_id,
      r.arn as to_id,
      null as id,
      'assumes' as title,
      'vpc_flow_log_to_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Account ID', r.account_id
      ) as properties
    from
      flow_log as f
      left join aws_iam_role as r on f.deliver_logs_permission_arn = r.arn

    -- From VPC subnets (Flow Log created at subnet level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      subnet_arn as id,
      s.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'Subnet ID' , s.subnet_id,
        'Region', s.region,
        'Account ID', s.account_id
      ) as properties
    from
      flow_log as f
      left join aws_vpc_subnet as s on f.resource_id = s.subnet_id
    where
      resource_id like 'subnet-%'

    -- From VPC subnets (Flow Log created at subnet level) (edge)
    union all
    select
      subnet_arn as from_id,
      case when i.network_interface_id is not null then i.network_interface_id else f.flow_log_id end as to_id,
      null as id,
      'subnet' as title,
      case when i.network_interface_id is not null then 'vpc_subnet_to_ec2_network_interface' else 'vpc_subnet_to_vpc_flow_log' end as category,
      jsonb_build_object(
        'ARN', subnet_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      flow_log as f
      left join aws_vpc_subnet as s on f.resource_id = s.subnet_id
      left join aws_ec2_network_interface as i on i.subnet_id = s.subnet_id
    where
      resource_id like 'subnet-%'

    -- From VPC (Flow Log created at subnet level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      v.arn as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn ,
        'VPC ID' , v.vpc_id,
        'Region', v.region,
        'Default', v.is_default,
        'Account ID', v.account_id
      ) as properties
    from
      flow_log as f
      left join aws_vpc_subnet as s on f.resource_id = s.subnet_id
      right join aws_vpc as v on v.vpc_id = s.vpc_id
    where
      resource_id like 'subnet-%'

    -- From VPC (Flow Log created at subnet level) (edge)
    union all
    select
      v.arn as from_id,
      s.subnet_arn as to_id,
      null as id,
      'vpc' as title,
      'vpc_to_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      flow_log as f
      left join aws_vpc_subnet as s on f.resource_id = s.subnet_id
      right join aws_vpc as v on v.vpc_id = s.vpc_id
    where
      resource_id like 'subnet-%'

    -- From VPC (Flow Log created at VPC level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      v.arn as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'VPC ID' , v.vpc_id,
        'Region', v.region,
        'Default', v.is_default,
        'Account ID', v.account_id
      ) as properties
    from
      flow_log as f
      left join aws_vpc as v on v.vpc_id = f.resource_id
    where
      resource_id like 'vpc-%'

    -- From VPC (Flow Log created at VPC level) (edge)
    union all
    select
      v.arn as from_id,
      case when s.subnet_arn is not null then s.subnet_arn else f.flow_log_id end as to_id,
      null as id,
      'vpc' as title,
      case when s.subnet_arn is not null then 'vpc_to_vpc_subnet' else 'vpc_to_vpc_flow_log' end as category,
      jsonb_build_object(
        'ARN', v.arn,
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      flow_log as f
      left join aws_vpc as v on v.vpc_id = f.resource_id
      left join aws_vpc_subnet as s on v.vpc_id = s.vpc_id
    where
      resource_id like 'vpc-%'

    -- From VPC subnets (Flow Log created at VPC level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      subnet_arn as id,
      s.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'Subnet ID' , s.subnet_id,
        'Region', s.region,
        'Account ID', s.account_id
      ) as properties
    from
      flow_log as f
      left join aws_vpc as v on v.vpc_id = f.resource_id
      right join aws_vpc_subnet as s on v.vpc_id = s.vpc_id
    where
      resource_id like 'vpc-%'

    -- From VPC subnets (Flow Log created at VPC level) (edge)
    union all
    select
      subnet_arn as from_id,
      f.flow_log_id as to_id,
      null as id,
      'subnet' as title,
      'vpc_subnet_to_vpc_flow_log' as category,
      jsonb_build_object(
        'ARN', subnet_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      flow_log as f
      left join aws_vpc as v on v.vpc_id = f.resource_id
      right join aws_vpc_subnet as s on v.vpc_id = s.vpc_id
    where
      f.resource_id like 'vpc-%'

    -- From EC2 network interfaces (Flow Log created at ENI level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      network_interface_id as id,
      i.title as title,
      'aws_ec2_network_interface' as category,
      jsonb_build_object(
        'ID' , i.network_interface_id,
        'Region', i.region,
        'Account ID', i.account_id
      ) as properties
    from
      flow_log as f
      left join aws_ec2_network_interface as i on f.resource_id = i.network_interface_id
    where
      f.resource_id like 'eni-%'

    -- From EC2 network interfaces (Flow Log created at ENI level) (edge)
    union all
    select
      i.network_interface_id as from_id,
      f.flow_log_id as to_id,
      null as id,
      'eni' as title,
      'ec2_network_interface_to_vpc_flow_log' as category,
      jsonb_build_object(
        'ID', network_interface_id,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      flow_log as f
      left join aws_ec2_network_interface as i on f.resource_id = i.network_interface_id
    where
      resource_id like 'eni-%'

    -- From VPC subnets (Flow Log created at ENI level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.subnet_arn as id,
      s.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'Subnet ID' , s.subnet_id,
        'Region', s.region,
        'Account ID', s.account_id
      ) as properties
    from
      flow_log as f
      left join aws_ec2_network_interface as i on f.resource_id = i.network_interface_id
      left join aws_vpc_subnet as s on s.subnet_id = i.subnet_id
    where
      resource_id like 'eni-%'

    -- From VPC subnets (Flow Log created at ENI level) (edge)
    union all
    select
      subnet_arn as from_id,
      i.network_interface_id as to_id,
      null as id,
      'subnet' as title,
      'vpc_subnet_to_ec2_network_interface' as category,
      jsonb_build_object(
        'ARN', subnet_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      flow_log as f
      left join aws_ec2_network_interface as i on f.resource_id = i.network_interface_id
      left join aws_vpc_subnet as s on s.subnet_id = i.subnet_id
    where
      resource_id like 'eni-%'

    -- From VPC (Flow Log created at ENI level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      v.arn as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'VPC ID' , v.vpc_id,
        'Region', v.region,
        'Default', v.is_default,
        'Account ID', v.account_id
      ) as properties
     from
      flow_log as f
      left join aws_ec2_network_interface as i on f.resource_id = i.network_interface_id
      left join aws_vpc as v on v.vpc_id = i.vpc_id
    where
      resource_id like 'eni-%'

    -- From VPC (Flow Log created at ENI level) (edge)
    union all
    select
      v.arn as from_id,
      s.subnet_arn as to_id,
      null as id,
      'vpc' as title,
      'vpc_to_vpc_subnet' as category,
      jsonb_build_object(
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      flow_log as f
      left join aws_ec2_network_interface as i on f.resource_id = i.network_interface_id
      left join aws_vpc as v on v.vpc_id = i.vpc_id
      left join aws_vpc_subnet as s on s.subnet_id = i.subnet_id
    where
      resource_id like 'eni-%'

    order by
      from_id,
      to_id;

  EOQ
  param "flow_log_id" {}

}

query "aws_vpc_flow_log_overview" {
  sql = <<-EOQ
    select
      flow_log_id as "Flow Log ID",
      creation_time as "Creation Time",
      flow_log_status as "Status",
      max_aggregation_interval as "Max Aggregation Interval",
      title as "Title",
      region as "Region",
      account_id as "Account ID"
    from
      aws_vpc_flow_log
    where
      flow_log_id = $1
  EOQ

  param "flow_log_id" {}
}

query "aws_vpc_flow_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_vpc_flow_log,
      jsonb_array_elements(tags_src) as tag
    where
      flow_log_id = $1
    order by
      tag ->> 'Key';
  EOQ

  param "flow_log_id" {}
}

query "aws_vpc_flow_log_destination" {
  sql = <<-EOQ
    select
      log_destination_type as "Log Destination Type",
      case when log_destination is not null then log_destination else '' end as "Bucket",
      case when log_group_name is not null then log_group_name else '' end as "Log Group"
    from
      aws_vpc_flow_log
    where
      flow_log_id = $1
  EOQ

  param "flow_log_id" {}
}

