dashboard "aws_vpc_flow_log_detail" {

  title         = "AWS VPC Flow Logs Detail"
  documentation = file("./dashboards/vpc/docs/vpc_flow_log_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "flow_log_id" {
    title = "Select a flow log:"
    sql   = query.aws_vpc_flow_log_input.sql
    width = 4
  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_vpc_flow_log_relationships_graph
      args  = {
        flow_log_id = self.input.flow_log_id.value
      }

      category "aws_vpc_flow_log" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_flow_logs_light.svg"))
      }

      category "aws_vpc" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
        href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
      }

      category "aws_vpc_network_acl" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_network_acl_light.svg"))
      }

      category "aws_iam_role" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/iam_role_light.svg"))
        href = "${dashboard.aws_iam_role_detail.url_path}?input.role_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_s3_bucket" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/s3_bucket_light.svg"))
        href = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_cloudwatch_log_group" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/cloudwatch_log_light.svg"))
      }

      category "aws_ec2_network_interface" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_network_interface_light.svg"))
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
        'region', region,
        'flow_log_id', flow_log_id
      ) as tags
    from
      aws_vpc_flow_log
    order by
      title;
  EOQ
}

query "aws_vpc_flow_log_relationships_graph" {
  sql = <<-EOQ
  with flow_log as (select * from aws_vpc_flow_log where flow_log_id = $1)

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

    -- To S3 Buckets (node)
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

    -- To S3 Buckets (edge)
    union all
    select
      f.flow_log_id as from_id,
      s.arn as to_id,
      null as id,
      'log destination' as title,
      'log destination' as category,
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

    -- To CloudWatch Logs (node)
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

    -- To Cloudwatch Logs (edge)
    union all
    select
      f.flow_log_id as from_id,
      c.arn as to_id,
      null as id,
      'logs to' as title,
      'logs to' as category,
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

    -- To IAM Roles (node)
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

    -- To IAM Roles (edge)
    union all
    select
      f.flow_log_id as from_id,
      r.arn as to_id,
      null as id,
      'permission' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Account ID', r.account_id
      ) as properties
    from
      flow_log as f
      left join aws_iam_role as r on f.deliver_logs_permission_arn = r.arn

    -- From Subnets (Flow Log created at subnet level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      subnet_arn as id,
      s.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'ID' , s.subnet_id,
        'Region', s.region,
        'Account ID', s.account_id
      ) as properties
    from
      flow_log as f
      left join aws_vpc_subnet as s on f.resource_id = s.subnet_id
    where
      resource_id like 'subnet-%'

    -- From Subnet (Flow Log created at subnet level) (edge)
    union all
    select
      subnet_arn as from_id,
      case when i.network_interface_id is not null then i.network_interface_id else f.flow_log_id end as to_id,
      null as id,
      'subnet' as title,
      'subnet' as category,
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
        'ID' , v.vpc_id,
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
      'VPC' as title,
      'VPC' as category,
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
        'ID' , v.vpc_id,
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
      'VPC' as title,
      'VPC' as category,
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

    -- From Subnet (Flow Log created at VPC level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      subnet_arn as id,
      s.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'ID' , s.subnet_id,
        'Region', s.region,
        'Account ID', s.account_id
      ) as properties
    from
      flow_log as f
      left join aws_vpc as v on v.vpc_id = f.resource_id
      right join aws_vpc_subnet as s on v.vpc_id = s.vpc_id
    where
      resource_id like 'vpc-%'

    -- From Subnet (Flow Log created at VPC level) (edge)
    union all
    select
      subnet_arn as from_id,
      f.flow_log_id as to_id,
      null as id,
      'subnet' as title,
      'subnet' as category,
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

    -- From ENI (Flow Log created at ENI level) (node)
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

    -- From ENI (Flow Log created at ENI level) (edge)
    union all
    select
      i.network_interface_id as from_id,
      f.flow_log_id as to_id,
      null as id,
      'eni' as title,
      'eni' as category,
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

      -- From ENI > Subnet (Flow Log created at ENI level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.subnet_arn as id,
      s.title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'ID' , s.subnet_id,
        'Region', s.region,
        'Account ID', s.account_id
      ) as properties
    from
      flow_log as f
      left join aws_ec2_network_interface as i on f.resource_id = i.network_interface_id
      left join aws_vpc_subnet as s on s.subnet_id = i.subnet_id
    where
      resource_id like 'eni-%'

    -- From ENI > Subnet (Flow Log created at ENI level) (edge)
    union all
    select
      subnet_arn as from_id,
      i.network_interface_id as to_id,
      null as id,
      'subnet' as title,
      'subnet' as category,
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

    -- From ENI > Subnet > VPC (Flow Log created at ENI level) (node)
    union all
    select
      null as from_id,
      null as to_id,
      v.arn as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ID' , v.vpc_id,
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

    -- From ENI > Subnet > VPC (Flow Log created at ENI level) (edge)
    union all
    select
      v.arn as from_id,
      s.subnet_arn as to_id,
      null as id,
      'VPC' as title,
      'VPC' as category,
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

  EOQ
  param "flow_log_id" {}

}
