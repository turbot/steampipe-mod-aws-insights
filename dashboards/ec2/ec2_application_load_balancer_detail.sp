dashboard "ec2_application_load_balancer_detail" {
  title         = "AWS EC2 Application Load Balancer Detail"
  documentation = file("./dashboards/ec2/docs/ec2_application_load_balancer_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "alb" {
    title = "Select an Application Load balancer:"
    query = query.alb_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.alb_state
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.alb_scheme
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.alb_ip_type
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.alb_az_zone
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.alb_logging_enabled
      args = {
        arn = self.input.alb.value
      }
    }

    card {
      width = 2
      query = query.alb_deletion_protection
      args = {
        arn = self.input.alb.value
      }
    }

  }

  container {
    graph {
      title = "Relationships"
      type  = "graph"

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

        args = [self.input.alb.value]
      }

      with "cloudfront_distributions" {
        sql = <<-EOQ
          select
            d.arn as distribution_arn
          from
            aws_cloudfront_distribution as d,
            jsonb_array_elements(origins) as origin
            left join aws_ec2_application_load_balancer as b on b.dns_name = origin ->> 'DomainName'
          where
            b.arn = any($1);
        EOQ

        args = [self.input.alb.value]
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

        args = [self.input.alb.value]
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

        args = [self.input.alb.value]
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

        args = [self.input.alb.value]
      }

      with "s3_buckets" {
        sql = <<-EOQ
          select
            b.arn as bucket_arn
          from
            aws_s3_bucket b,
            aws_ec2_application_load_balancer as alb,
            jsonb_array_elements(alb.load_balancer_attributes) attributes
          where
            alb.arn = $1
            and attributes ->> 'Key' = 'access_logs.s3.bucket'
            and b.name = attributes ->> 'Value';
        EOQ

        args = [self.input.alb.value]
      }

      with "vpc_security_groups" {
        sql = <<-EOQ
          select
            sg.group_id
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

        args = [self.input.alb.value]
      }

      with "vpc_subnets" {
        sql = <<-EOQ
          select
            s.subnet_id as subnet_id
          from
            aws_vpc_subnet s,
            aws_ec2_application_load_balancer as alb,
            jsonb_array_elements(availability_zones) as az
          where
            alb.arn = $1
            and s.subnet_id = az ->> 'SubnetId';
        EOQ

        args = [self.input.alb.value]
      }

      with "vpc_vpcs" {
        sql = <<-EOQ
          select
            alb.vpc_id as vpc_id
          from
            aws_ec2_application_load_balancer as alb
          where
            alb.arn = $1;
        EOQ

        args = [self.input.alb.value]
      }

      nodes = [
        node.acm_certificate,
        node.cloudfront_distribution,
        node.ec2_application_load_balancer,
        node.ec2_instance,
        node.ec2_load_balancer_listener,
        node.ec2_target_group,
        node.s3_bucket,
        node.vpc_security_group,
        node.vpc_subnet,
        node.vpc_vpc
      ]

      edges = [
        edge.ec2_application_load_balancer_to_acm_certificate,
        edge.ec2_application_load_balancer_to_cloudfront_distribution,
        edge.ec2_application_load_balancer_to_s3_bucket,
        edge.ec2_application_load_balancer_to_vpc_security_group,
        edge.ec2_application_load_balancer_to_vpc_subnet,
        edge.ec2_alb_to_target_group,
        edge.ec2_load_balancer_listener_to_ec2_load_balancer,
        edge.ec2_target_group_to_ec2_instance,
        edge.vpc_subnet_to_vpc_vpc
      ]

      args = {
        acm_certificate_arns               = with.acm_certificates.rows[*].certificate_arn
        cloudfront_distribution_arns       = with.cloudfront_distributions.rows[*].distribution_arn
        ec2_application_load_balancer_arns = [self.input.alb.value]
        ec2_instance_arns                  = with.ec2_instances.rows[*].instance_arn
        ec2_load_balancer_listener_arns    = with.ec2_load_balancer_listeners.rows[*].listener_arn
        ec2_target_group_arns              = with.ec2_target_groups.rows[*].target_group_arn
        s3_bucket_arns                     = with.s3_buckets.rows[*].bucket_arn
        vpc_security_group_ids             = with.vpc_security_groups.rows[*].group_id
        vpc_subnet_ids                     = with.vpc_subnets.rows[*].subnet_id
        vpc_vpc_ids                        = with.vpc_vpcs.rows[*].vpc_id
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.ec2_alb_overview
      args = {
        arn = self.input.alb.value
      }

    }

    table {
      title = "Tags"
      width = 3
      query = query.ec2_alb_tags
      args = {
        arn = self.input.alb.value
      }
    }

    table {
      title = "Attributes"
      width = 6
      query = query.ec2_alb_attributes
      args = {
        arn = self.input.alb.value
      }
    }
  }

}

query "alb_input" {
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

query "ec2_alb_overview" {
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

query "ec2_alb_tags" {
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

query "ec2_alb_attributes" {
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

query "alb_ip_type" {
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

query "alb_logging_enabled" {
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

query "alb_deletion_protection" {
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

query "alb_az_zone" {
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

query "alb_state" {
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

query "alb_scheme" {
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
