dashboard "ec2_gateway_load_balancer_detail" {
  title         = "AWS EC2 Gateway Load Balancer Detail"
  documentation = file("./dashboards/ec2/docs/ec2_gateway_load_balancer_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "glb" {
    title = "Select a Gateway Load balancer:"
    query = query.glb_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.glb_state
      args = {
        arn = self.input.glb.value
      }
    }

    card {
      width = 2
      query = query.glb_az_zone
      args = {
        arn = self.input.glb.value
      }
    }

    card {
      width = 2
      query = query.glb_deletion_protection
      args = {
        arn = self.input.glb.value
      }
    }

  }

  with "acm_certificates" {
    sql = <<-EOQ
      select
        c.certificate_arn
      from
        aws_acm_certificate c,
        jsonb_array_elements_text(in_use_by) u
      where
        u = $1
    EOQ

    args = [self.input.glb.value]
  }

  with "ec2_instances" {
    sql = <<-EOQ
      select
        instance.arn as instance_arn
      from
        aws_ec2_target_group tg,
        aws_ec2_instance instance,
        jsonb_array_elements(tg.target_health_descriptions) thd
      where
        instance.instance_id = thd -> 'Target' ->> 'Id'
        and $1 in
        (
          select
            jsonb_array_elements_text(tg.load_balancer_arns)
        );
    EOQ

    args = [self.input.glb.value]
  }

  with "ec2_load_balancer_listeners" {
    sql = <<-EOQ
      select
        arn as listener_arn
      from
        aws_ec2_load_balancer_listener
      where
        load_balancer_arn = $1;
    EOQ

    args = [self.input.glb.value]
  }

  with "ec2_target_groups" {
    sql = <<-EOQ
      select
        tg.target_group_arn
      from
        aws_ec2_target_group tg
      where
        $1 in
        (
          select
            jsonb_array_elements_text(tg.load_balancer_arns)
        );
    EOQ

    args = [self.input.glb.value]
  }

  with "s3_buckets" {
    sql = <<-EOQ
      select
        b.arn as bucket_arn
      from
        aws_s3_bucket b,
        aws_ec2_gateway_load_balancer as alb,
        jsonb_array_elements(alb.load_balancer_attributes) attributes
      where
        alb.arn = $1
        and attributes ->> 'Key' = 'access_logs.s3.bucket'
        and b.name = attributes ->> 'Value';
    EOQ

    args = [self.input.glb.value]
  }

  with "vpc_security_groups" {
    sql = <<-EOQ
      select
        sg.group_id
      from
        aws_vpc_security_group sg,
        aws_ec2_gateway_load_balancer as alb
      where
        alb.arn = $1
        and sg.group_id in
        (
          select
            jsonb_array_elements_text(alb.security_groups)
        );
    EOQ

    args = [self.input.glb.value]
  }

  with "vpc_subnets" {
    sql = <<-EOQ
      select
        s.subnet_id as subnet_id
      from
        aws_vpc_subnet s,
        aws_ec2_gateway_load_balancer as alb,
        jsonb_array_elements(availability_zones) as az
      where
        alb.arn = $1
        and s.subnet_id = az ->> 'SubnetId';
    EOQ

    args = [self.input.glb.value]
  }

  with "vpc_vpcs" {
    sql = <<-EOQ
      select
        alb.vpc_id as vpc_id
      from
        aws_ec2_gateway_load_balancer as alb
      where
        alb.arn = $1;
    EOQ

    args = [self.input.glb.value]
  }

  container {
    graph {
      title = "Relationships"
      type  = "graph"

      node {
        base = node.acm_certificate
        args = {
          acm_certificate_arns = with.acm_certificates.rows[*].certificate_arn
        }
      }

      node {
        base = node.ec2_gateway_load_balancer
        args = {
          ec2_gateway_load_balancer_arns = [self.input.glb.value]
        }
      }

      node {
        base = node.ec2_instance
        args = {
          ec2_instance_arns = with.ec2_instances.rows[*].instance_arn
        }
      }

      node {
        base = node.ec2_load_balancer_listener
        args = {
          ec2_load_balancer_listener_arns = with.ec2_load_balancer_listeners.rows[*].listener_arn
        }
      }

      node {
        base = node.ec2_target_group
        args = {
          ec2_target_group_arns = with.ec2_target_groups.rows[*].target_group_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups.rows[*].group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets.rows[*].subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs.rows[*].vpc_id
        }
      }

      edge {
        base = edge.ec2_gateway_load_balancer_to_acm_certificate
        args = {
          ec2_gateway_load_balancer_arns = [self.input.glb.value]
        }
      }

      edge {
        base = edge.ec2_gateway_load_balancer_to_ec2_target_group
        args = {
          ec2_gateway_load_balancer_arns = [self.input.glb.value]
        }
      }

      edge {
        base = edge.ec2_gateway_load_balancer_to_s3_bucket
        args = {
          ec2_gateway_load_balancer_arns = [self.input.glb.value]
        }
      }

      edge {
        base = edge.ec2_gateway_load_balancer_to_vpc_security_group
        args = {
          ec2_gateway_load_balancer_arns = [self.input.glb.value]
        }
      }

      edge {
        base = edge.ec2_gateway_load_balancer_to_vpc_subnet
        args = {
          ec2_gateway_load_balancer_arns = [self.input.glb.value]
        }
      }

      edge {
        base = edge.ec2_load_balancer_listener_to_ec2_load_balancer
        args = {
          ec2_load_balancer_listener_arns = with.ec2_load_balancer_listeners.rows[*].listener_arn
        }
      }

      edge {
        base = edge.ec2_target_group_to_ec2_instance
        args = {
          ec2_target_group_arns = with.ec2_target_groups.rows[*].target_group_arn
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets.rows[*].subnet_id
        }
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.ec2_glb_overview
      args = {
        arn = self.input.glb.value
      }

    }

    table {
      title = "Tags"
      width = 3
      query = query.ec2_glb_tags
      args = {
        arn = self.input.glb.value
      }
    }

    table {
      title = "Attributes"
      width = 6
      query = query.ec2_glb_attributes
      args = {
        arn = self.input.glb.value
      }
    }
  }

}

query "glb_input" {
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

query "ec2_glb_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      created_time as "Created Time",
      dns_name as "DNS Name",
      canonical_hosted_zone_id as "Route 53 Hosted Zone ID",
      account_id as "Account ID",
      region as "Region",
      arn as "ARN"
    from
      aws_ec2_gateway_load_balancer
    where
      aws_ec2_gateway_load_balancer.arn = $1;
  EOQ

  param "arn" {}
}

query "ec2_glb_tags" {
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

query "ec2_glb_attributes" {
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

query "glb_logging_enabled" {
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

query "glb_deletion_protection" {
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

query "glb_az_zone" {
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

query "glb_state" {
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
