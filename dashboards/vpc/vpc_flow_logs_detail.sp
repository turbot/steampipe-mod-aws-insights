dashboard "vpc_flow_logs_detail" {

  title         = "AWS VPC Flow Logs Detail"
  documentation = file("./dashboards/vpc/docs/vpc_flow_logs_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "flow_log_id" {
    title = "Select a flow log:"
    query = query.vpc_flow_log_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.vpc_flow_log_resource_id
      args = {
        flow_log_id = self.input.flow_log_id.value
      }
    }

    card {
      width = 2
      query = query.vpc_flow_log_deliver_logs_status
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

      with "cloudwatch_log_groups" {
        sql = <<-EOQ
          select
            distinct g.arn as log_group_arn
          from
            aws_vpc_flow_log as f,
            aws_cloudwatch_log_group as g
          where
            f.log_group_name = g.name
            and f.log_destination_type = 'cloud-watch-logs'
            and f.region = g.region
            and f.flow_log_id = $1;
        EOQ

        args = [self.input.flow_log_id.value]
      }

      with "ec2_network_interfaces" {
        sql = <<-EOQ
          select
            resource_id as eni_id
          from
            aws_vpc_flow_log
          where
            resource_id like 'eni-%'
            and flow_log_id = $1;
        EOQ

        args = [self.input.flow_log_id.value]
      }

      with "iam_roles" {
        sql = <<-EOQ
          select
            deliver_logs_permission_arn as role_arn
          from
            aws_vpc_flow_log
          where
            deliver_logs_permission_arn is not null
            and flow_log_id = $1;
        EOQ

        args = [self.input.flow_log_id.value]
      }

      with "s3_buckets" {
        sql = <<-EOQ
          select
            distinct s.arn as bucket_arn
          from
            aws_vpc_flow_log as f,
            aws_s3_bucket as s
          where
            f.bucket_name = s.name
            and f.log_destination_type = 's3'
            and f.flow_log_id = $1;
        EOQ

        args = [self.input.flow_log_id.value]
      }

      with "vpc_subnets" {
        sql = <<-EOQ
          select
            resource_id as subnet_id
          from
            aws_vpc_flow_log
          where
            resource_id like 'subnet-%'
            and flow_log_id = $1;
        EOQ

        args = [self.input.flow_log_id.value]
      }

      with "vpc_vpcs" {
        sql = <<-EOQ
          select
            resource_id as vpc_id
          from
            aws_vpc_flow_log
          where
            resource_id like 'vpc-%'
            and flow_log_id = $1;
        EOQ

        args = [self.input.flow_log_id.value]
      }

      nodes = [
        node.cloudwatch_log_group,
        node.ec2_network_interface,
        node.iam_role,
        node.s3_bucket,
        node.vpc_flow_log,
        node.vpc_subnet,
        node.vpc_vpc
      ]

      edges = [
        edge.ec2_network_interface_to_vpc_flow_log,
        edge.vpc_flow_log_to_cloudwatch_log_group,
        edge.vpc_flow_log_to_iam_role,
        edge.vpc_flow_log_to_s3_bucket,
        edge.vpc_subnet_to_vpc_flow_log,
        edge.vpc_to_vpc_flow_log
      ]

      args = {
        cloudwatch_log_group_arns = with.cloudwatch_log_groups.rows[*].log_group_arn
        ec2_network_interface_ids = with.ec2_network_interfaces.rows[*].eni_id
        iam_role_arns             = with.iam_roles.rows[*].role_arn
        s3_bucket_arns            = with.s3_buckets.rows[*].bucket_arn
        vpc_flow_log_ids          = [self.input.flow_log_id.value]
        vpc_subnet_ids            = with.vpc_subnets.rows[*].subnet_id
        vpc_vpc_ids               = with.vpc_vpcs.rows[*].vpc_id
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
        query = query.vpc_flow_log_overview
        args = {
          flow_log_id = self.input.flow_log_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.vpc_flow_tags
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
        query = query.vpc_flow_log_destination
        args = {
          flow_log_id = self.input.flow_log_id.value
        }

        column "Bucket" {
          href = "${dashboard.s3_bucket_detail.url_path}?input.bucket_arn={{.'Bucket' | @uri}}"

        }
      }

    }

  }

}

query "vpc_flow_log_input" {
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

query "vpc_flow_log_resource_id" {
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

query "vpc_flow_log_deliver_logs_status" {
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

node "vpc_flow_log" {
  category = category.vpc_flow_log

  sql = <<-EOQ
    select
      flow_log_id as id,
      title as title,
      jsonb_build_object(
        'Flow Log ID', flow_log_id,
        'Status', flow_log_status,
        'Creation Time', creation_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_flow_log
    where
      flow_log_id = any($1);
  EOQ

  param "vpc_flow_log_ids" {}
}

edge "vpc_flow_log_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    select
      flow_log_id as from_id,
      b.arn as to_id
    from
      aws_vpc_flow_log as f,
      aws_s3_bucket as b
    where
      f.bucket_name = b.name
      and f.log_destination_type = 's3'
      and f.flow_log_id = any($1);
  EOQ

  param "vpc_flow_log_ids" {}
}

edge "vpc_flow_log_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      flow_log_id as from_id,
      g.arn as to_id
    from
      aws_vpc_flow_log as f,
      aws_cloudwatch_log_group as g
    where
      f.log_group_name = g.name
      and f.log_destination_type = 'cloud-watch-logs'
      and f.region = g.region
      and f.flow_log_id = any($1);
  EOQ

  param "vpc_flow_log_ids" {}
}

edge "vpc_flow_log_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      flow_log_id as from_id,
      deliver_logs_permission_arn as to_id
    from
      aws_vpc_flow_log
    where
      flow_log_id = any($1);
  EOQ

  param "vpc_flow_log_ids" {}
}

query "vpc_flow_log_overview" {
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

query "vpc_flow_tags" {
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

query "vpc_flow_log_destination" {
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

