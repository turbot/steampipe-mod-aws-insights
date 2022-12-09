dashboard "ec2_classic_load_balancer_detail" {
  title         = "AWS EC2 Classic Load Balancer Detail"
  documentation = file("./dashboards/ec2/docs/ec2_classic_load_balancer_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "clb" {
    title = "Select a Classic Load balancer:"
    query = query.clb_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.clb_scheme
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.clb_instances
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.clb_logging_enabled
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.clb_az_zone
      args = {
        arn = self.input.clb.value
      }
    }

    card {
      width = 2
      query = query.clb_cross_zone_enabled
      args = {
        arn = self.input.clb.value
      }
    }

  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

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

        args = [self.input.clb.value]
      }

      with "ec2_instances" {
        sql = <<-EOQ
          select
            i.arn as instance_arn
          from
            aws_ec2_classic_load_balancer as clb
            cross join jsonb_array_elements(clb.instances) as ci
            left join aws_ec2_instance i on i.instance_id = ci ->> 'InstanceId'
          where
            clb.arn = $1;
        EOQ

        args = [self.input.clb.value]
      }

      with "ec2_load_balancer_listeners" {
        sql = <<-EOQ
          select
            lblistener.arn as listener_arn
          from
            aws_ec2_load_balancer_listener lblistener
          where
            lblistener.load_balancer_arn = $1;
        EOQ

        args = [self.input.clb.value]
      }

      with "s3_buckets" {
        sql = <<-EOQ
          select
            b.arn as bucket_arn
          from
            aws_s3_bucket b,
            aws_ec2_classic_load_balancer as clb
          where
            clb.arn = $1
            and b.name = clb.access_log_s3_bucket_name;
        EOQ

        args = [self.input.clb.value]
      }

      with "vpc_security_groups" {
        sql = <<-EOQ
          select
            sg.group_id
          from
            aws_vpc_security_group sg,
            aws_ec2_classic_load_balancer as alb
          where
            alb.arn = $1
            and sg.group_id in
            (
              select
                jsonb_array_elements_text(alb.security_groups)
            );
        EOQ

        args = [self.input.clb.value]
      }

      with "vpc_subnets" {
        sql = <<-EOQ
          select
            s.subnet_id as subnet_id
          from
            aws_vpc_subnet s,
            aws_ec2_classic_load_balancer as alb,
            jsonb_array_elements(availability_zones) as az
          where
            alb.arn = $1
            and s.subnet_id = az ->> 'SubnetId';
        EOQ

        args = [self.input.clb.value]
      }

      with "vpc_vpcs" {
        sql = <<-EOQ
          select
            alb.vpc_id as vpc_id
          from
            aws_ec2_classic_load_balancer as alb
          where
            alb.arn = $1;
        EOQ

        args = [self.input.clb.value]
      }

      nodes = [
        node.acm_certificate,
        node.ec2_classic_load_balancer,
        node.ec2_instance,
        node.ec2_load_balancer_listener,
        node.s3_bucket,
        node.vpc_security_group,
        node.vpc_subnet,
        node.vpc_vpc
      ]

      edges = [
        edge.ec2_classic_load_balancer_to_acm_certificate,
        edge.ec2_classic_load_balancer_to_ec2_instance,
        edge.ec2_classic_load_balancer_to_s3_bucket,
        edge.ec2_classic_load_balancer_to_vpc_security_group,
        edge.ec2_classic_load_balancer_to_vpc_subnet,
        edge.ec2_load_balancer_listener_to_ec2_lb,
        edge.vpc_subnet_to_vpc_vpc
      ]

      args = {
        acm_certificate_arns            = with.acm_certificates.rows[*].certificate_arn
        ec2_classic_load_balancer_arns  = [self.input.clb.value]
        ec2_instance_arns               = with.ec2_instances.rows[*].instance_arn
        ec2_load_balancer_listener_arns = with.ec2_load_balancer_listeners.rows[*].listener_arn
        s3_bucket_arns                  = with.s3_buckets.rows[*].bucket_arn
        vpc_security_group_ids          = with.vpc_security_groups.rows[*].group_id
        vpc_subnet_ids                  = with.vpc_subnets.rows[*].subnet_id
        vpc_vpc_ids                     = with.vpc_vpcs.rows[*].vpc_id
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.ec2_clb_overview
      args = {
        arn = self.input.clb.value
      }

    }

    table {
      title = "Tags"
      width = 3
      query = query.ec2_clb_tags
      args = {
        arn = self.input.clb.value
      }
    }
  }

}

query "clb_input" {
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

query "ec2_clb_overview" {
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

query "ec2_clb_tags" {
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

query "clb_logging_enabled" {
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

query "clb_az_zone" {
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

query "clb_cross_zone_enabled" {
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

query "clb_instances" {
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

query "clb_scheme" {
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