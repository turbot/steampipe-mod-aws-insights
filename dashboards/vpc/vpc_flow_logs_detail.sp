dashboard "aws_vpc_flow_logs_detail" {

  title         = "AWS VPC Flow Logs Detail"
  documentation = file("./dashboards/vpc/docs/vpc_flow_logs_detail.md")

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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_vpc_flow_log_node,
        node.aws_vpc_flow_log_to_s3_bucket_node,
        node.aws_vpc_flow_log_to_cloudwatch_log_group_node,
        node.aws_vpc_flow_log_to_iam_role_node,
        node.aws_vpc_flow_log_from_ec2_network_interface_node,
        node.aws_vpc_flow_log_from_vpc_subnet_node,
        node.aws_vpc_flow_log_from_vpc_node
      ]

      edges = [
        edge.aws_vpc_flow_log_to_s3_bucket_edge,
        edge.aws_vpc_flow_log_to_cloudwatch_log_group_edge,
        edge.aws_vpc_flow_log_to_iam_role_edge,
        edge.aws_vpc_flow_log_from_ec2_network_interface_edge,
        edge.aws_vpc_flow_log_from_vpc_subnet_edge,
        edge.aws_vpc_flow_log_from_vpc_edge
      ]

      args = {
        flow_log_id = self.input.flow_log_id.value
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

node "aws_vpc_flow_log_node" {
  category = category.aws_vpc_flow_log
  sql = <<-EOQ
    select
      flow_log_id as id,
      title as title,
      jsonb_build_object(
        'Status', flow_log_status,
        'Creation Time', creation_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_flow_log
    where
      flow_log_id = $1
  EOQ

  param "flow_log_id" {}
}

node "aws_vpc_flow_log_to_s3_bucket_node" {
  category = category.aws_s3_bucket
  sql = <<-EOQ
    select
      s.arn as id,
      s.title as title,
      jsonb_build_object(
        'ARN', s.arn,
        'Region', s.region,
        'Account ID', s.account_id
      ) as properties
    from
      aws_vpc_flow_log as f
      left join aws_s3_bucket as s on f.bucket_name = s.name
    where
      f.log_destination_type = 's3'
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

edge "aws_vpc_flow_log_to_s3_bucket_edge" {
  title = "logs to"
  sql = <<-EOQ
    select
      f.flow_log_id as from_id,
      s.arn as to_id
    from
      aws_vpc_flow_log as f
      left join aws_s3_bucket as s on f.bucket_name = s.name
    where
      f.log_destination_type = 's3'
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

node "aws_vpc_flow_log_to_cloudwatch_log_group_node" {
  category = category.aws_cloudwatch_log_group
  sql = <<-EOQ
    select
      c.arn as id,
      c.title as title,
      jsonb_build_object(
        'ARN', c.arn,
        'Region', c.region,
        'Account ID', c.account_id
      ) as properties
    from
      aws_vpc_flow_log as f
      left join aws_cloudwatch_log_group as c on f.log_group_name = c.name
    where
      f.log_destination_type = 'cloud-watch-logs'
      and f.region = c.region
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

edge "aws_vpc_flow_log_to_cloudwatch_log_group_edge" {
  title = "logs to"
  sql = <<-EOQ
    select
      f.flow_log_id as from_id,
      c.arn as to_id
    from
      aws_vpc_flow_log as f
      left join aws_cloudwatch_log_group as c on f.log_group_name = c.name
    where
      f.log_destination_type = 'cloud-watch-logs'
      and f.region = c.region
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

node "aws_vpc_flow_log_to_iam_role_node" {
  category = category.aws_iam_role
  sql = <<-EOQ
    select
      r.arn as id,
      r.title as title,
      jsonb_build_object(
        'ARN', r.arn,
        'Account ID', r.account_id
      ) as properties
    from
      aws_vpc_flow_log as f
      left join aws_iam_role as r on f.deliver_logs_permission_arn = r.arn
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

edge "aws_vpc_flow_log_to_iam_role_edge" {
  title = "assumes"
  sql = <<-EOQ
    select
      f.flow_log_id as from_id,
      r.arn as to_id
    from
      aws_vpc_flow_log as f
      left join aws_iam_role as r on f.deliver_logs_permission_arn = r.arn
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

node "aws_vpc_flow_log_from_ec2_network_interface_node" {
  category = category.aws_ec2_network_interface
  sql = <<-EOQ
    select
      network_interface_id as id,
      i.title as title,
      'aws_ec2_network_interface' as category,
      jsonb_build_object(
        'ID' , i.network_interface_id,
        'Region', i.region,
        'Account ID', i.account_id
      ) as properties
    from
      aws_vpc_flow_log as f
      left join aws_ec2_network_interface as i on f.resource_id = i.network_interface_id
    where
      f.resource_id like 'eni-%'
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

edge "aws_vpc_flow_log_from_ec2_network_interface_edge" {
  title = "flow log"
  sql = <<-EOQ
    select
      i.network_interface_id as from_id,
      f.flow_log_id as to_id
    from
      aws_vpc_flow_log as f
      left join aws_ec2_network_interface as i on f.resource_id = i.network_interface_id
    where
      resource_id like 'eni-%'
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

node "aws_vpc_flow_log_from_vpc_subnet_node" {
  category = category.aws_vpc_subnet
  sql = <<-EOQ
     select
      s.subnet_arn as id,
      s.title as title,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'Subnet ID' , s.subnet_id,
        'Region', s.region,
        'Account ID', s.account_id
      ) as properties
    from
      aws_vpc_flow_log as f
      left join aws_vpc_subnet as s on f.resource_id = s.subnet_id
    where
      resource_id like 'subnet-%'
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

edge "aws_vpc_flow_log_from_vpc_subnet_edge" {
  title = "flow log"
  sql = <<-EOQ
    select
      s.subnet_arn as from_id,
      f.flow_log_id as to_id
    from
      aws_vpc_flow_log as f
      left join aws_vpc_subnet as s on f.resource_id = s.subnet_id
    where
      resource_id like 'subnet-%'
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

node "aws_vpc_flow_log_from_vpc_node" {
  category = category.aws_vpc
  sql = <<-EOQ
     select
      v.arn as id,
      v.title as title,
      jsonb_build_object(
        'ARN', v.arn,
        'VPC ID' , v.vpc_id,
        'Region', v.region,
        'Default', v.is_default,
        'Account ID', v.account_id
      ) as properties
    from
      aws_vpc_flow_log as f
      left join aws_vpc as v on f.resource_id = v.vpc_id
    where
      resource_id like 'vpc-%'
      and f.flow_log_id = $1;
  EOQ

  param "flow_log_id" {}
}

edge "aws_vpc_flow_log_from_vpc_edge" {
  title = "flow log"
  sql = <<-EOQ
    select
      v.arn as from_id,
      f.flow_log_id as to_id
    from
      aws_vpc_flow_log as f
      left join aws_vpc as v on f.resource_id = v.vpc_id
    where
      resource_id like 'vpc-%'
      and f.flow_log_id = $1;
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
      case when log_destination like 'arn:aws:s3%' then log_destination else 'NA' end as "Bucket",
      case
        when log_destination like '%:log-group:%' then log_destination
        When log_group_name is not null then log_group_name
        else 'NA' end as "Log Group"
    from
      aws_vpc_flow_log
    where
      flow_log_id = $1
  EOQ

  param "flow_log_id" {}
}

