dashboard "aws_ec2_application_load_balancer_detail" {
  title         = "AWS EC2 Application Load Balancer Detail"
  documentation = file("./dashboards/ec2/docs/ec2_application_load_balancer_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "alb" {
    title = "Select an Application Load balancer:"
    query = query.aws_alb_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_alb_state
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.aws_alb_scheme
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.aws_alb_ip_type
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.aws_alb_az_zone
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.aws_alb_logging_enabled
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.aws_alb_deletion_protection
      args = {
        arn = self.input.alb.value
      }
    }

  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_ec2_application_load_balancer_node,
        node.aws_ec2_alb_to_vpc_security_group_node,
        node.aws_ec2_alb_to_vpc_subnet_node,
        node.aws_ec2_alb_to_s3_bucket_node,
        node.aws_ec2_alb_vpc_security_group_to_vpc_node,
        node.aws_ec2_lb_to_target_group_node,
        node.aws_ec2_lb_to_ec2_instance_node,
        node.aws_ec2_lb_from_ec2_load_balancer_listener_node
      ]

      edges = [
        edge.aws_ec2_alb_to_vpc_subnet_edge,
        edge.aws_ec2_alb_to_vpc_security_group_edge,
        edge.aws_ec2_alb_to_s3_bucket_edge,
        edge.aws_ec2_alb_vpc_security_group_to_vpc_edge,
        edge.aws_ec2_lb_to_target_group_edge,
        edge.aws_ec2_lb_to_ec2_instance_edge,
        edge.aws_ec2_lb_from_ec2_load_balancer_listener_edge
      ]

      args = {
        arn = self.input.alb.value
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.aws_ec2_alb_overview
      args = {
        arn = self.input.alb.value
      }

    }

    table {
      title = "Tags"
      width = 3
      query = query.aws_ec2_alb_tags
      args = {
        arn = self.input.alb.value
      }
    }

    table {
      title = "Attributes"
      width = 6
      query = query.aws_ec2_alb_attributes
      args = {
        arn = self.input.alb.value
      }
    }
  }

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

query "aws_ec2_alb_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      created_time as "Created Time",
      dns_name as "DNS Name",
      canonical_hosted_zone_id as "Route 53 hosted zone ID",
      account_id as "Account ID",
      region as "Region",
      arn as "ARN"
    from
      aws_ec2_application_load_balancer
    where
      aws_ec2_application_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_alb_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ec2_application_load_balancer,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}

query "aws_ec2_alb_attributes" {
  sql = <<-EOQ
    select
      lb ->> 'Key' as "Key",
      lb ->> 'Value' as "Value"
    from
      aws_ec2_application_load_balancer
      cross join jsonb_array_elements(load_balancer_attributes) as lb
    where
      aws_ec2_application_load_balancer.arn = $1
      and lb ->> 'Key' not in ( 'deletion_protection.enabled' ,'access_logs.s3.enabled' )
    order by
      lb ->> 'Key';
    EOQ

  param "arn" {}
}

query "aws_alb_ip_type" {
  sql = <<-EOQ
    select
      'IP Address Type' as label,
      case when ip_address_type = 'ipv4' then 'IPv4' else initcap(ip_address_type) end as value
    from
      aws_ec2_application_load_balancer
    where
      aws_ec2_application_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_alb_logging_enabled" {
  sql = <<-EOQ
    select
      'Logging' as label,
      case when lb ->> 'Value' = 'false' then 'Disabled' else 'Enabled' end as value,
      case when lb ->> 'Value' = 'false' then 'alert' else 'ok' end as type
    from
      aws_ec2_application_load_balancer
      cross join jsonb_array_elements(load_balancer_attributes) as lb
    where
      lb ->> 'Key' = 'access_logs.s3.enabled'
      and aws_ec2_application_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_alb_deletion_protection" {
  sql = <<-EOQ
    select
      'Deletion Protection' as label,
      case when lb ->> 'Value' = 'false' then 'Disabled' else 'Enabled' end as value,
      case when lb ->> 'Value' = 'false' then 'alert' else 'ok' end as type
    from
      aws_ec2_application_load_balancer
      cross join jsonb_array_elements(load_balancer_attributes) as lb
    where
      lb ->> 'Key' = 'deletion_protection.enabled'
      and aws_ec2_application_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_alb_az_zone" {
  sql = <<-EOQ
    select
      'Availibility Zones' as label,
      count(az ->> 'ZoneName') as value,
      case when count(az ->> 'ZoneName') > 1 then 'ok' else 'alert' end as type
    from
      aws_ec2_application_load_balancer
      cross join jsonb_array_elements(availability_zones) as az
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_alb_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(state_code) as value
    from
      aws_ec2_application_load_balancer
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_alb_scheme" {
  sql = <<-EOQ
    select
      'Scheme' as label,
      initcap(scheme) as value
    from
      aws_ec2_application_load_balancer
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ec2_application_load_balancer_node" {
  category = category.aws_ec2_application_load_balancer

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'State Code', state_code,
        'Account ID', account_id,
        'VPC ID', vpc_id,
        'Region', region,
        'DNS Name', dns_name
      ) as properties
    from
      aws_ec2_application_load_balancer
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ec2_alb_to_vpc_subnet_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      s.subnet_id as id,
      s.title as title,
      jsonb_build_object(
        'Subnet ID', s.subnet_id,
        'ARN', s.subnet_arn,
        'VPC ID', s.vpc_id,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_vpc_subnet s,
      aws_ec2_application_load_balancer as alb,
      jsonb_array_elements(availability_zones) as az
    where
      alb.arn = $1
      and s.subnet_id = az ->> 'SubnetId';
  EOQ

  param "arn" {}
}

edge "aws_ec2_alb_to_vpc_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      sg as from_id,
      s.subnet_id as to_id
    from
      aws_vpc_subnet s,
      aws_ec2_application_load_balancer as alb,
      jsonb_array_elements_text(alb.security_groups) as sg,
      jsonb_array_elements(availability_zones) as az
    where
      alb.arn = $1
      and s.subnet_id = az ->> 'SubnetId';
  EOQ

  param "arn" {}
}

node "aws_ec2_alb_to_vpc_security_group_node" {
  category = category.aws_vpc_security_group

  sql = <<-EOQ
    select
      sg.group_id as id,
      sg.title as title,
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
      aws_ec2_application_load_balancer as alb
    where
      alb.arn = $1
      and sg.group_id in
      (
        select
          jsonb_array_elements_text(alb.security_groups)
      );
  EOQ

  param "arn" {}
}

edge "aws_ec2_alb_to_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      alb.arn as from_id,
      sg.group_id as to_id
    from
      aws_vpc_security_group sg,
      aws_ec2_application_load_balancer as alb
    where
      alb.arn = $1
      and sg.group_id in
      (
        select
          jsonb_array_elements_text(alb.security_groups)
      );
  EOQ

  param "arn" {}
}

node "aws_ec2_alb_to_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      b.arn as id,
      b.title as title,
      jsonb_build_object(
        'Name', b.name,
        'ARN', b.arn,
        'Account ID', alb.account_id,
        'Region', alb.region,
        'Logs to', attributes ->> 'Value'
      ) as properties
    from
      aws_s3_bucket b,
      aws_ec2_application_load_balancer as alb,
      jsonb_array_elements(alb.load_balancer_attributes) attributes
    where
      alb.arn = $1
      and attributes ->> 'Key' = 'access_logs.s3.bucket'
      and b.name = attributes ->> 'Value';
  EOQ

  param "arn" {}
}

edge "aws_ec2_alb_to_s3_bucket_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      alb.arn as from_id,
      b.arn as to_id
    from
      aws_s3_bucket b,
      aws_ec2_application_load_balancer as alb,
      jsonb_array_elements(alb.load_balancer_attributes) attributes
    where
      alb.arn = $1
      and attributes ->> 'Key' = 'access_logs.s3.bucket'
      and b.name = attributes ->> 'Value';
  EOQ

  param "arn" {}
}

node "aws_ec2_alb_vpc_security_group_to_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      vpc.vpc_id as id,
      vpc.title as title,
      jsonb_build_object(
        'VPC ID', vpc.vpc_id,
        'Account ID', vpc.account_id,
        'Region', vpc.region,
        'CIDR Block', vpc.cidr_block
      ) as properties
    from
      aws_vpc as vpc,
      aws_ec2_application_load_balancer as alb
    where
      alb.arn = $1
      and alb.vpc_id = vpc.vpc_id;
  EOQ

  param "arn" {}
}

edge "aws_ec2_alb_vpc_security_group_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      s.subnet_id as from_id,
      alb.vpc_id as to_id
    from
      aws_vpc_subnet s,
      aws_ec2_application_load_balancer as alb,
      jsonb_array_elements(availability_zones) as az
    where
      alb.arn = $1
      and s.subnet_id = az ->> 'SubnetId';
  EOQ

  param "arn" {}
}
