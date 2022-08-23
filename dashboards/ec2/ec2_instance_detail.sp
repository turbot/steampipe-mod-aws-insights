dashboard "aws_ec2_instance_detail" {

  title         = "AWS EC2 Instance Detail"
  documentation = file("./dashboards/ec2/docs/ec2_instance_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "instance_arn" {
    title = "Select an instance:"
    sql   = query.aws_ec2_instance_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_ec2_instance_status
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_instance_type
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_instance_total_cores_count
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_instance_public_access
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_instance_ebs_optimized
      args = {
        arn = self.input.instance_arn.value
      }
    }
  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_ec2_instance_relationships_graph
      args = {
        arn = self.input.instance_arn.value
      }

      category "aws_ec2_instance" {
        icon = local.aws_ec2_instance_icon
      }

      category "aws_ebs_volume" {
        // cyclic dependency prevents use of url_path, hardcode for now
        href = "/aws_insights.dashboard.aws_ebs_volume_detail?input.volume_arn={{.properties.'ARN' | @uri}}"
        #href = "${dashboard.aws_ebs_volume_detail.url_path}?input.volume_arn={{.properties.'ARN' | @uri}}"
        icon = local.aws_ebs_volume_icon
      }

      category "aws_ec2_network_interface" {
        icon = local.aws_ec2_network_interface_icon
      }

      category "aws_ec2_ami" {
        icon = local.aws_ec2_ami_icon
      }

      category "aws_vpc_security_group" {
        // cyclic dependency prevents use of url_path, hardcode for now
        href = "/aws_insights.dashboard.aws_vpc_security_group_detail?input.security_group_id={{.properties.'ID' | @uri}}"
        #href = "${dashboard.aws_vpc_security_group_detail.url_path}?input.security_group_id={{.properties.'ID' | @uri}}"
      }

      category "aws_vpc" {
        // cyclic dependency prevents use of url_path, hardcode for now
        href = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{.properties.'ID' | @uri}}"
        #href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
        icon = local.aws_vpc_icon
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
        query = query.aws_ec2_instance_overview
        args = {
          arn = self.input.instance_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_ec2_instance_tags
        args = {
          arn = self.input.instance_arn.value
        }
      }
    }
    container {
      width = 6

      table {
        title = "Block Device Mappings"
        query = query.aws_ec2_instance_block_device_mapping
        args = {
          arn = self.input.instance_arn.value
        }

        column "Volume ARN" {
          display = "none"
        }

        column "Volume ID" {
          // cyclic dependency prevents use of url_path, hardcode for now
          href = "/aws_insights.dashboard.aws_ebs_volume_detail?input.volume_arn={{.'Volume ARN' | @uri}}"
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Network Interfaces"
      query = query.aws_ec2_instance_network_interfaces
      args = {
        arn = self.input.instance_arn.value
      }
    }

  }

  container {
    width = 6

    table {
      title = "Security Groups"
      query = query.aws_ec2_instance_security_groups
      args = {
        arn = self.input.instance_arn.value
      }

      column "Group ID" {
        // cyclic dependency prevents use of url_path, hardcode for now
        href = "/aws_insights.dashboard.aws_vpc_security_group_detail?input.security_group_id={{.'Group ID' | @uri}}"
      }
    }

  }

  container {
    width = 6

    table {
      title = " CPU cores"
      query = query.aws_ec2_instance_cpu_cores
      args = {
        arn = self.input.instance_arn.value
      }
    }

  }

}

query "aws_ec2_instance_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'instance_id', instance_id
      ) as tags
    from
      aws_ec2_instance
    order by
      title;
  EOQ
}

query "aws_ec2_instance_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      instance_state as value
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}

}

query "aws_ec2_instance_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      instance_type as value
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_total_cores_count" {
  sql = <<-EOQ
    select
      'Total Cores' as label,
      sum(cpu_options_core_count) as value
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_public_access" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when public_ip_address is null then 'Disabled' else 'Enabled' end as value,
      case when public_ip_address is null then 'ok' else 'alert' end as type
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_ebs_optimized" {
  sql = <<-EOQ
    select
      'EBS Optimized' as label,
      case when ebs_optimized then 'Enabled' else 'Disabled' end as value,
      case when ebs_optimized then 'ok' else 'alert' end as type
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_relationships_graph" {
  sql = <<-EOQ
    with instances as
    (
      select
        arn,
        instance_id,
        tags,
        account_id,
        region,
        block_device_mappings,
        security_groups,
        vpc_id,
        subnet_id,
        iam_instance_profile_arn,
        iam_instance_profile_id,
        image_id,
        key_name
      from
        aws_ec2_instance
      where
        arn = $1
    )
    select
      null as from_id,
      null as to_id,
      instance_id as id,
      instance_id as title,
      'aws_ec2_instance' as category,
      jsonb_build_object('Name', tags ->> 'Name', 'Instance ID', instance_id, 'ARN', arn, 'Account ID', account_id, 'Region', region) as properties
    from
      instances

    -- To EBS volumes (node)
    union all
    select
      null as from_id,
      null as to_id,
      bd -> 'Ebs' ->> 'VolumeId' as id,
      bd -> 'Ebs' ->> 'VolumeId' as title,
      'aws_ebs_volume' as category,
      jsonb_build_object('Volume ID', bd -> 'Ebs' ->> 'VolumeId', 'Account ID', account_id, 'Region', region) as properties
    from
      instances,
      jsonb_array_elements(block_device_mappings) as bd

    -- To EBS volumes (edge)
    union all
    select
      instance_id as from_id,
      bd -> 'Ebs' ->> 'VolumeId' as to_id,
      null as id,
      'mounts' as title,
      'edge_mounts' as category,
      jsonb_build_object('Volume ID', bd -> 'Ebs' ->> 'VolumeId', 'Device Name', bd ->> 'DeviceName', 'Status', bd -> 'Ebs' ->> 'Status', 'Attach Time', bd -> 'Ebs' ->> 'AttachTime', 'Delete On Termination', bd -> 'Ebs' ->> 'DeleteOnTermination') as properties
    from
      instances,
      jsonb_array_elements(block_device_mappings) as bd

    -- To EC2 ENIs (node)
    union all
    select
      null as from_id,
      null as to_id,
      eni.network_interface_id as id,
      eni.network_interface_id as title,
      'aws_ec2_network_interface' as category,
      jsonb_build_object('Name', eni.tags ->> 'Name', 'Description', eni.description, 'Interface ID', eni.network_interface_id, 'Public IP', eni.association_public_ip, 'Private IP', eni.private_ip_address, 'Public DNS Name', eni.association_public_dns_name, 'Private DNS Name', eni.private_dns_name, 'MAC Address', eni.mac_address, 'Account ID', eni.account_id, 'Region', eni.region) as properties
    from
      instances as i,
      aws_ec2_network_interface as eni
    where
      eni.attached_instance_id = i.instance_id

    -- To EC2 ENIs (edge)
    union all
    select
      instance_id as from_id,
      eni.network_interface_id as to_id,
      null as id,
      'eni' as title,
      'edge_eni' as category,
      jsonb_build_object('Status', status, 'Attachment ID', attachment_id, 'Attachment Status', attachment_status, 'Attachment Time', attachment_time, 'Delete on Instance Termination', delete_on_instance_termination, 'Device Index', device_index) as properties
    from
      instances as i,
      aws_ec2_network_interface as eni
    where
      eni.attached_instance_id = i.instance_id

    -- To VPC security groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      sg ->> 'GroupId' as id,
      sg ->> 'GroupId' as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object('ID', sg ->> 'GroupId', 'Name', sg ->> 'GroupName', 'Account ID', account_id, 'Region', region) as properties
    from
      instances,
      jsonb_array_elements(security_groups) as sg

    -- To VPC security groups (edge)
    union all
    select
      instance_id as from_id,
      sg ->> 'GroupId' as to_id,
      null as id,
      'security group' as title,
      'edge_security_group' as category,
      jsonb_build_object('ID', sg ->> 'GroupId', 'Name', sg ->> 'GroupName', 'Account ID', account_id, 'Region', region) as properties
    from
      instances,
      jsonb_array_elements(security_groups) as sg

    -- To VPC subnets (node)
    union all
    select
      null as from_id,
      null as to_id,
      subnet.subnet_id as id,
      subnet.subnet_id as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object('Name', subnet.tags ->> 'Name', 'Subnet ID', subnet.subnet_id , 'VPC ID', subnet.vpc_id , 'CIDR Block', subnet.cidr_block, 'AZ', subnet.availability_zone, 'Account ID', subnet.account_id, 'Region', subnet.region) as properties
    from
      instances as i,
      aws_vpc_subnet as subnet
    where
      i.subnet_id = subnet.subnet_id

    -- To VPC subnets (edge)
    union all
    select
      i.instance_id as from_id,
      i.subnet_id as to_id,
      null as id,
      'subnet' as title,
      'edge_subnet' as category,
      jsonb_build_object('Name', subnet.tags ->> 'Name', 'Subnet ID', subnet.subnet_id, 'State', subnet.state) as properties
    from
      instances as i,
      aws_vpc_subnet as subnet
    where
      i.subnet_id = subnet.subnet_id

    -- To VPCs (node)
    union all
    select
      null as from_id,
      null as to_id,
      vpc.vpc_id as id,
      vpc.tags ->> 'Name' as title,
      'aws_vpc' as category,
      jsonb_build_object('ID', vpc.vpc_id, 'Name', vpc.tags ->> 'Name', 'CIDR Block', vpc.cidr_block, 'Account ID', vpc.account_id, 'Owner ID', vpc.owner_id, 'Region', vpc.region) as properties
    from
      instances,
      aws_vpc as vpc
    where
      instances.vpc_id = vpc.vpc_id

    -- To VPCs (edge)
    union all
    select
      instances.subnet_id as from_id,
      vpc.vpc_id as to_id,
      null as id,
      'vpc' as title,
      'edge_vpc' as category,
      jsonb_build_object('ID', vpc.vpc_id, 'Name', vpc.tags ->> 'Name', 'CIDR Block', vpc.cidr_block, 'Account ID', vpc.account_id, 'Owner ID', vpc.owner_id, 'Region', vpc.region) as properties
    from
      instances,
      aws_vpc as vpc
    where
      instances.vpc_id = vpc.vpc_id

    -- To IAM instance profiles (node)
    union all
    select
      null as from_id,
      null as to_id,
      iam_instance_profile_arn as id,
      split_part(iam_instance_profile_arn, ':', 6) as title,
      'iam_instance_profile_arn' as category,
      jsonb_build_object('Instance Profile ARN', iam_instance_profile_arn, 'Instance Profile ID', iam_instance_profile_id) as properties
    from
      instances

    -- To IAM instance profiles (edge)
    union all
    select
      instance_id as from_id,
      iam_instance_profile_arn as to_id,
      null as id,
      'runs as' as title,
      'edge_runs_as' as category,
      jsonb_build_object('Instance Profile ARN', iam_instance_profile_arn, 'Instance Profile ID', iam_instance_profile_id) as properties
    from
      instances

    -- To IAM roles for instance profiles (node)
    union all
    select
      null as from_id,
      null as to_id,
      r.arn as id,
      r.name as title,
      'aws_iam_role' as category,
      jsonb_build_object('Name', r.name, 'Description', r.description, 'ARN', r.arn , 'Account ID', r.account_id) as properties
    from
      instances as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      instance_profile = i.iam_instance_profile_arn

    -- To IAM roles for instance profiles (edge)
    union all
    select
      i.iam_instance_profile_arn as from_id,
      r.arn as to_id,
      null as id,
      'assumes' as title,
      'edge_assumes' as category,
      jsonb_build_object('Role ARN', r.arn, 'Instance Profile ARN', i.iam_instance_profile_arn, 'Account ID', r.account_id) as properties
    from
      instances as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      instance_profile = i.iam_instance_profile_arn

    -- To EC2 key pairs (node)
    union all
    select
      null as from_id,
      null as to_id,
      i.key_name as id,
      i.key_name as title,
      'aws_ec2_key_pair' as category,
      jsonb_build_object('Name', k.key_name, 'ID', k.key_pair_id, 'Fingerprint', key_fingerprint) as properties
    from
      instances as i,
      aws_ec2_key_pair as k
    where
      i.key_name = k.key_name
      and i.account_id = k.account_id
      and i.region = k.region

    -- To EC2 key pairs (edge)
    union all
    select
      instance_id as from_id,
      key_name as to_id,
      null as id,
      'key pair' as title,
      'edge_keypair' as category,
      jsonb_build_object('Name', key_name, 'Instance ID', instance_id) as properties
    from
      instances as i

    -- From EC2 AMIs (node)
    union all
    select
      null as from_id,
      null as to_id,
      image_id as id,
      image_id as title,
      'aws_ec2_ami' as category,
      jsonb_build_object('Image ID', image_id) as properties
    from
      instances as i

    -- From EC2 AMIs (edge)
    union all
    select
      instance_id as from_id,
      image_id as to_id,
      null as id,
      'launched from' as title,
      'edge_launched_from' as category,
      jsonb_build_object('Image ID', image_id, 'Instance ID', instance_id) as properties
    from
      instances as i

    -- From AutoScaling groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      k.autoscaling_group_arn as id,
      k.name as title,
      'aws_ec2_autoscaling_group' as category,
      jsonb_build_object('instance', group_instance ->> 'InstanceId', 'i', instances.instance_id, 'asg', group_instance) as properties
    from
      aws_ec2_autoscaling_group as k,
      jsonb_array_elements(k.instances) as group_instance,
      instances
    where
      group_instance ->> 'InstanceId' = instances.instance_id

    -- From AutoScaling groups (edge)
    union all
    select
      k.autoscaling_group_arn as from_id,
      instances.instance_id as to_id,
      null as id,
      'launches' as title,
      'edge_launches' as category,
      jsonb_build_object() as properties
    from
      aws_ec2_autoscaling_group as k,
      jsonb_array_elements(k.instances) as group_instance,
      instances
    where
      group_instance ->> 'InstanceId' = instances.instance_id

    -- From EC2 classic load balancers (node)
    union all
    select
      null as from_id,
      null as to_id,
      k.arn as id,
      k.name as title,
      'aws_ec2_classic_load_balancer' as category,
      jsonb_build_object('instance', group_instance ->> 'InstanceId', 'i', instances.instance_id, 'clb', group_instance) as properties
    from
      aws_ec2_classic_load_balancer as k,
      jsonb_array_elements(k.instances) as group_instance,
      instances
    where
      group_instance ->> 'InstanceId' = instances.instance_id

    -- From EC2 classic load balancers (edge)
    union all
    select
      k.arn as from_id,
      instances.instance_id as to_id,
      null as id,
      'routes to' as title,
      'edge_routes_to' as category,
      jsonb_build_object('instance', group_instance ->> 'InstanceId', 'i', instances.instance_id, 'clb', group_instance) as properties
    from
      aws_ec2_classic_load_balancer as k,
      jsonb_array_elements(k.instances) as group_instance,
      instances
    where
      group_instance ->> 'InstanceId' = instances.instance_id

    -- From EC2 target groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      target.target_group_arn as id,
      target.target_group_name as title,
      'aws_ec2_target_group' as category,
      jsonb_build_object('Name', target.target_group_name, 'ARN', target.target_group_arn, 'Region', target.region, 'Account ID', target.account_id) as properties
    from
      instances as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id

    -- From EC2 target groups (edge)
    union all
    select
      target.target_group_arn as from_id,
      i.instance_id as to_id,
      null as id,
      'routes to' as title,
      'edge_routes_to' as category,
      jsonb_build_object('Name', target.target_group_name, 'ARN', target.target_group_arn, 'Region', target.region, 'Account ID', target.account_id, 'Health Check Enabled', target.health_check_enabled) as properties
    from
      instances as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_overview" {
  sql = <<-EOQ
    select
      tags ->> 'Name' as "Name",
      instance_id as "Instance ID",
      launch_time as "Launch Time",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_ec2_instance
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ec2_instance,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}

query "aws_ec2_instance_block_device_mapping" {
  sql = <<-EOQ
    with volume_details as (
    select
      p -> 'Ebs' ->> 'VolumeId'  as "Volume ID",
      p ->> 'DeviceName'  as "Device Name",
      p -> 'Ebs' ->> 'AttachTime' as "Attach Time",
      p -> 'Ebs' ->> 'DeleteOnTermination' as "Delete On Termination",
      p -> 'Ebs' ->> 'Status'  as "Status",
      arn
    from
      aws_ec2_instance,
      jsonb_array_elements(block_device_mappings) as p
    where
      arn = $1
    )
    select
      "Volume ID",
      "Device Name",
      "Attach Time",
      "Delete On Termination",
      "Status",
      v.arn as "Volume ARN"
    from
      volume_details as vd
      left join aws_ebs_volume v on v.volume_id = vd."Volume ID"
    where
      v.volume_id in (select "Volume ID" from volume_details)
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_security_groups" {
  sql = <<-EOQ
    select
      p ->> 'GroupId'  as "Group ID",
      p -> 'GroupName' ->> 'AttachTime' as "Group Name"
    from
      aws_ec2_instance,
      jsonb_array_elements(security_groups) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_network_interfaces" {
  sql = <<-EOQ
    select
      p ->> 'NetworkInterfaceId' as "Network Interface ID",
      p ->> 'InterfaceType' as "Interface Type",
      p ->> 'Status' as "Status",
      p ->> 'SubnetId' as "Subnet ID",
      p ->> 'VpcId' as "VPC ID"
    from
      aws_ec2_instance,
      jsonb_array_elements(network_interfaces) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_cpu_cores" {
  sql = <<-EOQ
    select
      cpu_options_core_count  as "CPU Options Core Count",
      cpu_options_threads_per_core  as "CPU Options Threads Per Core"
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}
