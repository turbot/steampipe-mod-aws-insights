edge "ec2_ami_to_ec2_instance_edge" {
  title = "instance"

  sql = <<-EOQ
    select
      image_id as from_id,
      arn as to_id
    from
      aws_ec2_instance
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_application_load_balancer_to_acm_certificate" {
  title = "ssl via"

  sql = <<-EOQ
    select
      u as from_id,
      c.certificate_arn as to_id
    from
      aws_acm_certificate c,
      jsonb_array_elements_text(in_use_by) u
    where
      u = any($1)
  EOQ

  param "ec2_application_load_balancer_arns" {}
}

edge "ec2_application_load_balancer_to_cloudfront_distribution" {
  title = "origin for"

  sql = <<-EOQ
    select
      b.arn as from_id,
      d.arn as to_id
    from
      aws_cloudfront_distribution as d
      join unnest($1::text[]) as a on d.arn = a and d.account_id = split_part(a, ':', 5) and d.region = split_part(a, ':', 4),
      jsonb_array_elements(origins) as origin
      left join aws_ec2_application_load_balancer as b on b.dns_name = origin ->> 'DomainName';
  EOQ

  param "cloudfront_distribution_arns" {}
}

edge "ec2_application_load_balancer_to_ec2_target_group" {
  title = "target group"

  sql = <<-EOQ
    select
      lb_arns as from_id,
      tg.target_group_arn as to_id
    from
      aws_ec2_target_group tg,
      jsonb_array_elements_text(tg.load_balancer_arns) as lb_arns
    where
      lb_arns = any($1);
  EOQ

  param "ec2_application_load_balancer_arns" {}
}

edge "ec2_application_load_balancer_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    with s3_bucket as (
      select
        name,
        arn
      from
        aws_s3_bucket
    ), ec2_application_load_balancer as (
      select
        load_balancer_attributes,
        arn
      from
        aws_ec2_application_load_balancer
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      alb.arn as from_id,
      b.arn as to_id
    from
      s3_bucket b,
      ec2_application_load_balancer as alb,
      jsonb_array_elements(alb.load_balancer_attributes) attributes
    where
      attributes ->> 'Key' = 'access_logs.s3.bucket'
      and b.name = attributes ->> 'Value';
  EOQ

  param "ec2_application_load_balancer_arns" {}
}

edge "ec2_application_load_balancer_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      alb.arn as from_id,
      sg.group_id as to_id
    from
      aws_vpc_security_group sg,
      aws_ec2_application_load_balancer as alb
      join unnest($1::text[]) as a on alb.arn = a and alb.account_id = split_part(a, ':', 5) and alb.region = split_part(a, ':', 4)
    where
      sg.group_id in
      (
        select
          jsonb_array_elements_text(alb.security_groups)
      );
  EOQ

  param "ec2_application_load_balancer_arns" {}
}

edge "ec2_application_load_balancer_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      sg as from_id,
      s.subnet_id as to_id
    from
      aws_vpc_subnet s,
      aws_ec2_application_load_balancer as alb
      join unnest($1::text[]) as a on alb.arn = a and alb.account_id = split_part(a, ':', 5) and alb.region = split_part(a, ':', 4),
      jsonb_array_elements_text(alb.security_groups) as sg,
      jsonb_array_elements(availability_zones) as az
    where
      s.subnet_id = az ->> 'SubnetId';
  EOQ

  param "ec2_application_load_balancer_arns" {}
}

edge "ec2_autoscaling_group_to_ec2_instance" {
  title = "launches"

  sql = <<-EOQ
    select
      k.autoscaling_group_arn as from_id,
      i.arn as to_id
    from
      aws_ec2_autoscaling_group as k,
      jsonb_array_elements(k.instances) as group_instance,
      aws_ec2_instance as i
    where
      i.arn = any($1)
      and group_instance ->> 'InstanceId' = i.instance_id;
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_classic_load_balancer_to_acm_certificate" {
  title = "ssl via"

  sql = <<-EOQ
    select
      u as from_id,
      c.certificate_arn as to_id
    from
      aws_acm_certificate c,
      jsonb_array_elements_text(in_use_by) u
    where
      u = any($1)
  EOQ

  param "ec2_classic_load_balancer_arns" {}
}

edge "ec2_classic_load_balancer_to_ec2_instance" {
  title = "routes to"

  sql = <<-EOQ
    select
      clb.arn as from_id,
      i.arn as to_id
    from
      aws_ec2_classic_load_balancer as clb
      join unnest($1::text[]) as a on clb.arn = a and clb.account_id = split_part(a, ':', 5) and clb.region = split_part(a, ':', 4)
      cross join jsonb_array_elements(clb.instances) as ci
      left join aws_ec2_instance i on i.instance_id = ci ->> 'InstanceId';
  EOQ

  param "ec2_classic_load_balancer_arns" {}
}

edge "ec2_classic_load_balancer_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    with s3_bucket as (
      select
       name,
       arn
      from
        aws_s3_bucket
    ), ec2_classic_load_balancer as (
      select
       arn,
       access_log_s3_bucket_name
      from
        aws_ec2_classic_load_balancer
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    )
    select
      clb.arn as from_id,
      b.arn as to_id
    from
      s3_bucket b,
      ec2_classic_load_balancer as clb
    where
      b.name = clb.access_log_s3_bucket_name;
  EOQ

  param "ec2_classic_load_balancer_arns" {}
}

edge "ec2_classic_load_balancer_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      clb.arn as from_id,
      sg.group_id as to_id
    from
      aws_vpc_security_group sg,
      aws_ec2_classic_load_balancer as clb
      join unnest($1::text[]) as a on clb.arn = a and clb.account_id = split_part(a, ':', 5) and clb.region = split_part(a, ':', 4)
    where
      sg.group_id in
      (
        select
          jsonb_array_elements_text(clb.security_groups)
      );
  EOQ

  param "ec2_classic_load_balancer_arns" {}
}

edge "ec2_classic_load_balancer_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      sg as from_id,
      s as to_id
    from
      aws_ec2_classic_load_balancer
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4),
      jsonb_array_elements_text(security_groups) as sg,
      jsonb_array_elements_text(subnets) as s
    where
      arn = any($1);
  EOQ

  param "ec2_classic_load_balancer_arns" {}
}

edge "ec2_gateway_load_balancer_to_acm_certificate" {
  title = "ssl via"

  sql = <<-EOQ
    select
      u as from_id,
      c.certificate_arn as to_id
    from
      aws_acm_certificate c,
      jsonb_array_elements_text(in_use_by) u
    where
      u = any($1);
  EOQ

  param "ec2_gateway_load_balancer_arns" {}
}

edge "ec2_gateway_load_balancer_to_ec2_target_group" {
  title = "target group"

  sql = <<-EOQ
    select
      lb_arns as from_id,
      tg.target_group_arn as to_id
    from
      aws_ec2_target_group tg,
      jsonb_array_elements_text(tg.load_balancer_arns) as lb_arns
    where
      lb_arns = any($1);
  EOQ

  param "ec2_gateway_load_balancer_arns" {}
}

edge "ec2_gateway_load_balancer_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    with s3_bucket as (
      select
        name,
        arn
      from
        aws_s3_bucket
    )
    select
      glb.arn as from_id,
      b.arn as to_id
    from
      s3_bucket b,
      aws_ec2_gateway_load_balancer as glb,
      jsonb_array_elements(glb.load_balancer_attributes) attributes
    where
      glb.arn = any($1)
      and attributes ->> 'Key' = 'access_logs.s3.bucket'
      and b.name = attributes ->> 'Value';
  EOQ

  param "ec2_gateway_load_balancer_arns" {}
}

edge "ec2_gateway_load_balancer_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      clb.arn as from_id,
      sg.group_id as to_id
    from
      aws_vpc_security_group sg,
      aws_ec2_gateway_load_balancer as clb
      join unnest($1::text[]) as a on clb.arn = a and clb.account_id = split_part(a, ':', 5) and clb.region = split_part(a, ':', 4)
    where
      sg.group_id in
      (
        select
          jsonb_array_elements_text(clb.security_groups)
      );
  EOQ

  param "ec2_gateway_load_balancer_arns" {}
}

edge "ec2_gateway_load_balancer_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      glb.arn as from_id,
      s.subnet_id as to_id
    from
      aws_vpc_subnet s,
      aws_ec2_gateway_load_balancer as glb
      join unnest($1::text[]) as a on glb.arn = a and glb.account_id = split_part(a, ':', 5) and glb.region = split_part(a, ':', 4),
      jsonb_array_elements(availability_zones) as az
    where
      s.subnet_id = az ->> 'SubnetId';
  EOQ

  param "ec2_gateway_load_balancer_arns" {}
}

edge "ec2_instance_to_ebs_volume" {
  title = "mounts"

  sql = <<-EOQ
    select
      i.arn as from_id,
      v.arn as to_id
    from
      aws_ec2_instance as i
      join unnest($1::text[]) as a on i.arn = a and i.account_id = split_part(a, ':', 5) and i.region = split_part(a, ':', 4),
      jsonb_array_elements(block_device_mappings) as bd,
      aws_ebs_volume as v
    where
      v.volume_id = bd -> 'Ebs' ->> 'VolumeId';
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_instance_to_ec2_key_pair" {
  title = "key pair"

  sql = <<-EOQ
    select
      arn as from_id,
      key_name as to_id
    from
      aws_ec2_instance as i
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    where
      key_name is not null;
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_instance_to_ec2_network_interface" {
  title = "eni"

  sql = <<-EOQ
    select
      arn as from_id,
      i ->> 'NetworkInterfaceId' as to_id
    from
      aws_ec2_instance
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
      join jsonb_array_elements(network_interfaces) as i on true;
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_instance_to_iam_instance_profile" {
  title = "runs as"

  sql = <<-EOQ
    select
      arn as from_id,
      iam_instance_profile_arn as to_id
    from
      aws_ec2_instance as i
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    where
      iam_instance_profile_arn is not null;
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_instance_to_vpc_security_group" {
  title = "security groups"

  sql = <<-EOQ
    select
      coalesce(
        i ->> 'NetworkInterfaceId',
        arn
      ) as from_id,
      s ->> 'GroupId' as to_id
    from
      aws_ec2_instance
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
      join jsonb_array_elements(network_interfaces) as i on true
      join jsonb_array_elements(security_groups) as s on true;
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_instance_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      s ->> 'GroupId' as from_id,
      subnet_id as to_id
    from
      aws_ec2_instance
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
      join jsonb_array_elements(security_groups) as s on true;
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_launch_configuration_to_ebs_snapshot" {
  title = "snapshot"

  sql = <<-EOQ
    select
      launch_config.launch_configuration_arn as from_id,
      bdm -> 'Ebs' ->> 'SnapshotId' as to_id
    from
      aws_ec2_launch_configuration as launch_config,
      jsonb_array_elements(launch_config.block_device_mappings) as bdm
    where
      bdm -> 'Ebs' ->> 'SnapshotId' = any($1);
  EOQ

  param "ebs_snapshot_ids" {}
}

edge "ec2_load_balancer_listener_to_ec2_load_balancer" {
  title = "listener for"

  sql = <<-EOQ
    select
      arn as from_id,
      load_balancer_arn as to_id
    from
      aws_ec2_load_balancer_listener
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "ec2_load_balancer_listener_arns" {}
}

edge "ec2_load_balancer_to_ec2_target_group" {
  title = "target group"

  sql = <<-EOQ
    select
      l as from_id,
      target.target_group_arn as to_id
    from
      aws_ec2_instance as i
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4),
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
      jsonb_array_elements_text(target.load_balancer_arns) as l
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id;
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_network_interface_to_vpc_eip" {
  title = "eip"

  sql = <<-EOQ
    select
      i.network_interface_id as from_id,
      e.arn as to_id
    from
      aws_vpc_eip as e
      left join aws_ec2_network_interface as i on e.network_interface_id = i.network_interface_id
    where
      i.network_interface_id = any($1);
  EOQ

  param "ec2_network_interface_ids" {}
}

edge "ec2_network_interface_to_vpc_flow_log" {
  title = "flow log"

  sql = <<-EOQ
    select
      resource_id as from_id,
      flow_log_id as to_id
    from
      aws_vpc_flow_log
    where
      resource_id = any($1);
  EOQ

  param "ec2_network_interface_ids" {}
}

edge "ec2_network_interface_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      network_interface_id as from_id,
      sg ->> 'GroupId' as to_id
    from
      aws_ec2_network_interface
      left join jsonb_array_elements(groups) as sg on true
    where
      network_interface_id = any($1);
  EOQ

  param "ec2_network_interface_ids" {}
}

edge "ec2_network_interface_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      coalesce(
        sg ->> 'GroupId',
        network_interface_id
      ) as from_id,
      subnet_id as to_id
    from
      aws_ec2_network_interface
      left join jsonb_array_elements(groups) as sg on true
    where
      network_interface_id = any($1)
  EOQ

  param "ec2_network_interface_ids" {}
}

edge "ec2_network_load_balancer_to_acm_certificate" {
  title = "ssl via"

  sql = <<-EOQ
    select
      u as from_id,
      c.certificate_arn as to_id
    from
      aws_acm_certificate c,
      jsonb_array_elements_text(in_use_by) u
    where
      u = any($1);
  EOQ

  param "ec2_network_load_balancer_arns" {}
}

edge "ec2_network_load_balancer_to_ec2_target_group" {
  title = "target group"

  sql = <<-EOQ
    select
      lb_arns as from_id,
      tg.target_group_arn as to_id
    from
      aws_ec2_target_group tg,
      jsonb_array_elements_text(tg.load_balancer_arns) as lb_arns
    where
      lb_arns = any($1);
  EOQ

  param "ec2_network_load_balancer_arns" {}
}

edge "ec2_network_load_balancer_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    with s3_bucket as (
      select
        arn,
        name
      from
        aws_s3_bucket
    )
    select
      nlb.arn as from_id,
      s3_buckets.arn as to_id
    from
      s3_bucket s3_buckets,
      aws_ec2_network_load_balancer as nlb
      join unnest($1::text[]) as a on nlb.arn = a and nlb.account_id = split_part(a, ':', 5) and nlb.region = split_part(a, ':', 4),
      jsonb_array_elements(nlb.load_balancer_attributes) attributes
    where
      nlb.arn = any($1)
      and attributes ->> 'Key' = 'access_logs.s3.bucket'
      and s3_buckets.name = attributes ->> 'Value';
  EOQ

  param "ec2_network_load_balancer_arns" {}
}

edge "ec2_network_load_balancer_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      clb.arn as from_id,
      sg.group_id as to_id
    from
      aws_vpc_security_group sg,
      aws_ec2_network_load_balancer as clb
      join unnest($1::text[]) as a on clb.arn = a and clb.account_id = split_part(a, ':', 5) and clb.region = split_part(a, ':', 4)
    where
      sg.group_id in
      (
        select
          jsonb_array_elements_text(clb.security_groups)
      );
  EOQ

  param "ec2_network_load_balancer_arns" {}
}

edge "ec2_network_load_balancer_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      glb.arn as from_id,
      s.subnet_id as to_id
    from
      aws_vpc_subnet s,
      aws_ec2_network_load_balancer as glb
      join unnest($1::text[]) as a on glb.arn = a and glb.account_id = split_part(a, ':', 5) and glb.region = split_part(a, ':', 4),
      jsonb_array_elements(availability_zones) as az
    where
      glb.arn = any($1)
      and s.subnet_id = az ->> 'SubnetId';
  EOQ

  param "ec2_network_load_balancer_arns" {}
}

edge "ec2_target_group_to_ec2_instance" {
  title = "routes to"

  sql = <<-EOQ
    select
      target.target_group_arn as from_id,
      i.arn as to_id
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target
      join unnest($1::text[]) as a on target.target_group_arn = a and target.account_id = split_part(a, ':', 5) and target.region = split_part(a, ':', 4),
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id;
  EOQ

  param "ec2_target_group_arns" {}
}

