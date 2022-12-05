edge "ec2_instance_to_ebs_volume" {
  title = "mounts"

  sql = <<-EOQ
    select
      i.arn as from_id,
      v.arn as to_id
    from
      aws_ec2_instance as i,
      jsonb_array_elements(block_device_mappings) as bd,
      aws_ebs_volume as v
    where
      v.volume_id = bd -> 'Ebs' ->> 'VolumeId'
      and i.arn = any($1);
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
      join jsonb_array_elements(network_interfaces) as i on true
    where
      arn = any($1);
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
      join jsonb_array_elements(network_interfaces) as i on true
      join jsonb_array_elements(security_groups) as s on true
    where
      arn = any($1);
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
      join jsonb_array_elements(security_groups) as s on true
    where
      arn = any($1);
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
    where
      iam_instance_profile_arn is not null
      and i.arn = any($1);
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_instance_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      i.iam_instance_profile_arn as from_id,
      r.arn as to_id
    from
      aws_ec2_instance as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      i.arn = $1
      and instance_profile = i.iam_instance_profile_arn;
  EOQ

  param "ec2_instance_arns" {}
  param "iam_role_arns" {}
}

edge "ec2_instance_to_ec2_key_pair" {
  title = "key pair"

  sql = <<-EOQ
    select
      arn as from_id,
      key_name as to_id
    from
      aws_ec2_instance as i
    where
      key_name is not null
      and i.arn = any($1);
  EOQ

  param "ec2_instance_arns" {}
}


edge "ec2_target_group_to_ec2_instance" {
  title = "routes to"

  sql = <<-EOQ
    select
      target.target_group_arn as from_id,
      i.arn as to_id
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions
    where
      i.arn = any($1)
      and health_descriptions -> 'Target' ->> 'Id' = i.instance_id;
  EOQ

  param "ec2_instance_arns" {}
}

edge "ec2_load_balancer_to_target_group" {
  title = "target group"

  sql = <<-EOQ
    select
      l as from_id,
      target.target_group_arn as to_id
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
      jsonb_array_elements_text(target.load_balancer_arns) as l
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id
      and i.arn = any($1);
  EOQ

  param "ec2_instance_arns" {}
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

edge "ec2_classic_load_balancer_to_ec2_instance" {
  title = "routes to"

  sql = <<-EOQ
    select
      clb.arn as from_id,
      i.arn as to_id
    from
      aws_ec2_classic_load_balancer as clb
      cross join jsonb_array_elements(clb.instances) as ci
      left join aws_ec2_instance i on i.instance_id = ci ->> 'InstanceId'
    where
      clb.arn = any($1);
  EOQ

  param "ec2_classic_load_balancer_arns" {}
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
