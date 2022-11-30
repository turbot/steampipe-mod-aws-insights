edge "ec2_instance_to_ebs_volume" {
  title = "mounts"

  sql = <<-EOQ
    select
      instance_arn as from_id,
      volume_arn as to_id
    from
      unnest($1::text[]) as instance_arn,
      unnest($2::text[]) as volume_arn
  EOQ

  param "instance_arns" {}
  param "volume_arns" {}
}

edge "ec2_instance_to_ec2_network_interface" {
  title = "eni"

  sql = <<-EOQ
    select
      instance_arn as from_id,
      eni_id as to_id
    from
      unnest($1::text[]) as instance_arn,
      unnest($2::text[]) as eni_id
  EOQ

  param "instance_arns" {}
  param "eni_ids" {}
}

edge "ec2_instance_to_vpc_security_group" {
  title = "security groups"

  sql = <<-EOQ
    select
      coalesce(
        eni_id,
        instance_arn
      ) as from_id,
      security_group_id as to_id
    from
      unnest($1::text[]) as instance_arn,
      unnest($2::text[]) as eni_id,
      unnest($3::text[]) as security_group_id
  EOQ

  param "instance_arns" {}
  param "eni_ids" {}
  param "security_group_ids" {}
}

edge "ec2_instance_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      security_group_id as from_id,
      subnet_id as to_id
    from
      unnest($1::text[]) as security_group_id,
      unnest($2::text[]) as subnet_id
  EOQ

  param "security_group_ids" {}
  param "subnet_ids" {}
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

  param "instance_arns" {}
}

edge "ec2_instance_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      i.iam_instance_profile_arn as from_id,
      role_arn as to_id
    from
      aws_ec2_instance as i,
      unnest($2::text[]) as role_arn
    where
      iam_instance_profile_arn is not null
      and i.arn = any($1);
  EOQ

  param "instance_arns" {}
  param "role_arns" {}
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

  param "instance_arns" {}
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

  param "instance_arns" {}
}

edge "ec2_instance_lb_target_group" {
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

  param "instance_arns" {}
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

  param "instance_arns" {}
}

edge "ec2_classic_load_balancer_to_ec2_instance" {
  title = "routes to"

  sql = <<-EOQ
    select
      clb_arn as from_id,
      instance_arn as to_id
    from
     unnest($1::text[]) as clb_arn,
     unnest($2::text[]) as instance_arn
  EOQ

  param "clb_arns" {}
  param "instance_arns" {}
}

edge "ec2_application_load_balancer_to_ec2_instance" {
  title = "routes to"

  sql = <<-EOQ
    select
      alb_arn as from_id,
      instance_arn as to_id
    from
     unnest($1::text[]) as alb_arn,
     unnest($2::text[]) as instance_arn
  EOQ

  param "alb_arns" {}
  param "instance_arns" {}
}

edge "ec2_network_load_balancer_to_ec2_instance" {
  title = "routes to"

  sql = <<-EOQ
    select
      nlb_arn as from_id,
      instance_arn as to_id
    from
     unnest($1::text[]) as nlb_arn,
     unnest($2::text[]) as instance_arn
  EOQ

  param "nlb_arns" {}
  param "instance_arns" {}
}

edge "ec2_gateway_load_balancer_to_ec2_instance" {
  title = "routes to"

  sql = <<-EOQ
    select
      glb_arn as from_id,
      instance_arn as to_id
    from
     unnest($1::text[]) as glb_arn,
     unnest($2::text[]) as instance_arn
  EOQ

  param "glb_arns" {}
  param "instance_arns" {}
}

edge "ec2_network_interface_to_vpc_eip" {
  title = "eip"

  sql = <<-EOQ
    select
      network_interface_id as from_id,
      eip_arn as to_id
    from
      unnest($1::text[]) as network_interface_id,
      unnest($2::text[]) as eip_arn
  EOQ

  param "network_interface_ids" {}
  param "eip_arns" {}
}
