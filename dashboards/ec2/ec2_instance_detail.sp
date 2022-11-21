dashboard "aws_ec2_instance_detail" {

  title         = "AWS EC2 Instance Detail"
  documentation = file("./dashboards/ec2/docs/ec2_instance_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "instance_arn" {
    title = "Select an instance:"
    query = query.aws_ec2_instance_input
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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_ec2_instance_node,
        node.aws_ec2_instance_to_ebs_volume_node,
        node.aws_ec2_instance_to_ec2_network_interface_node,
        node.aws_ec2_instance_to_vpc_security_group_node,
        node.aws_ec2_instance_to_vpc_subnet_node,
        node.aws_ec2_instance_vpc_subnet_to_vpc_node,
        node.aws_ec2_instance_to_iam_profile_node,
        node.aws_ec2_instance_to_iam_role_node,
        node.aws_ec2_instance_to_ec2_key_pair_node,
        # node.aws_ec2_instance_to_ec2_ami_node
        node.aws_ec2_instance_from_ec2_autoscaling_group_node,
        node.aws_ec2_instance_from_ec2_classic_load_balancer_node,
        node.aws_ec2_instance_from_ec2_target_group_node,

        node.aws_ec2_instance_from_ec2_alb_node,
        node.aws_ec2_instance_from_ec2_nlb_node,
        node.aws_ec2_instance_from_ec2_gwlb_node,
        node.aws_ec2_instance_ecs_cluster_node

      ]

      edges = [
        edge.aws_ec2_instance_to_ebs_volume_edge,
        edge.aws_ec2_instance_to_ec2_network_interface_edge,
        edge.aws_ec2_instance_to_vpc_security_group_edge,
        edge.aws_ec2_instance_to_vpc_subnet_edge,
        edge.aws_ec2_instance_vpc_subnet_to_vpc_edge,
        edge.aws_ec2_instance_to_iam_profile_edge,
        edge.aws_ec2_instance_to_iam_role_edge,
        edge.aws_ec2_instance_to_ec2_key_pair_edge,
        # edge.aws_ec2_instance_to_ec2_ami_edge,
        edge.aws_ec2_instance_from_ec2_autoscaling_group_edge,
        edge.aws_ec2_instance_from_ec2_classic_load_balancer_edge,
        edge.aws_ec2_instance_from_ec2_target_group_edge,

        edge.aws_ec2_instance_lb_target_group_edge,
        edge.aws_ec2_instance_from_cluster_edge
      ]

      args = {
        arn = self.input.instance_arn.value
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

      column "VPC ID" {
        // cyclic dependency prevents use of url_path, hardcode for now
        href = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{ .'VPC ID' | @uri }}"
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
      title = "CPU cores"
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
      initcap(instance_state) as value
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
      'Public IP Address' as label,
      case when public_ip_address is null then 'Disabled' else host(public_ip_address) end as value,
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

node "aws_ec2_instance_node" {
  category = category.aws_ec2_instance

  sql = <<-EOQ
    select
      instance_id as id,
      title,
      jsonb_build_object(
        'Instance ID', instance_id,
        'Name', tags ->> 'Name',
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ec2_instance_to_ebs_volume_node" {
  category = category.aws_ebs_volume

  sql = <<-EOQ
    select
      bd -> 'Ebs' ->> 'VolumeId' as id,
      v.title as title,
      jsonb_build_object(
        'ARN', v.arn,
        'Account ID', v.account_id,
        'Region', v.region,
        'Volume ID', bd -> 'Ebs' ->> 'VolumeId'
      ) as properties
    from
      aws_ec2_instance as i,
      jsonb_array_elements(block_device_mappings) as bd,
      aws_ebs_volume as v
    where
      v.volume_id = bd -> 'Ebs' ->> 'VolumeId'
      and i.arn = $1

  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_to_ebs_volume_edge" {
  title = "mounts"

  sql = <<-EOQ
    select
      instance_id as from_id,
      bd -> 'Ebs' ->> 'VolumeId' as to_id,
      jsonb_build_object(
        'Status', bd -> 'Ebs' ->> 'Status',
        'Attach Time', bd -> 'Ebs' ->> 'AttachTime',
        'Delete On Termination', bd -> 'Ebs' ->> 'DeleteOnTermination'
      ) as properties
    from
      aws_ec2_instance as i,
      jsonb_array_elements(block_device_mappings) as bd
    where
      i.arn = $1
  EOQ

  param "arn" {}
}

node "aws_ec2_instance_to_ec2_network_interface_node" {
  category = category.aws_ec2_network_interface

  sql = <<-EOQ
    select
      eni.network_interface_id as id,
      eni.title as title,
      jsonb_build_object(
        'Name', eni.tags ->> 'Name',
        'Description', eni.description,
        'Interface ID', eni.network_interface_id,
        'Public IP', eni.association_public_ip,
        'Private IP', eni.private_ip_address,
        'Public DNS Name', eni.association_public_dns_name,
        'Private DNS Name', eni.private_dns_name,
        'MAC Address', eni.mac_address,
        'Account ID', eni.account_id,
        'Region', eni.region
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ec2_network_interface as eni
    where
      i.arn = $1
      and eni.attached_instance_id = i.instance_id;
  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_to_ec2_network_interface_edge" {
  title = "eni"

  sql = <<-EOQ
    select
      instance_id as from_id,
      eni.network_interface_id as to_id,
      jsonb_build_object(
        'Attachment ID', attachment_id,
        'Attachment Status', attachment_status,
        'Attachment Time', attachment_time,
        'Delete on Instance Termination', delete_on_instance_termination,
        'Device Index', device_index
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ec2_network_interface as eni
    where
      i.arn = $1
      and eni.attached_instance_id = i.instance_id;
  EOQ

  param "arn" {}
}

node "aws_ec2_instance_to_vpc_security_group_node" {
  category = category.aws_vpc_security_group

  sql = <<-EOQ
    select
      sg ->> 'GroupId' as id,
      sg ->> 'GroupName' as title,
      jsonb_build_object(
        'Group ID', sg ->> 'GroupId',
        'Name', sg ->> 'GroupName',
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_instance as i,
      jsonb_array_elements(security_groups) as sg
    where
      i.arn = $1
  EOQ

  param "arn" {}
}

# edge "aws_ec2_instance_to_vpc_security_group_edge" {
#   title = "security groups"

#   sql = <<-EOQ
#     select
#       instance_id as from_id,
#       sg ->> 'GroupId' as to_id,
#       jsonb_build_object(
#         'Account ID', account_id
#       ) as properties
#     from
#       aws_ec2_instance as i,
#       jsonb_array_elements(security_groups) as sg
#     where
#       i.arn = $1;
#   EOQ

#   param "arn" {}
# }



edge "aws_ec2_instance_to_vpc_security_group_edge" {
  title = "security groups"

  sql = <<-EOQ
    select
      coalesce(
        eni.network_interface_id,
        i.instance_id
      ) as from_id,
      sg ->> 'GroupId' as to_id
    from
      aws_ec2_instance as i
      left join aws_ec2_network_interface as eni on i.instance_id = eni.attached_instance_id
      join jsonb_array_elements(security_groups) as sg on true
    where
      i.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ec2_instance_to_vpc_subnet_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      subnet.subnet_id as id,
      subnet.title as title,
      jsonb_build_object(
        'Name', subnet.tags ->> 'Name',
        'Subnet ID', subnet.subnet_id ,
        'VPC ID', subnet.vpc_id ,
        'CIDR Block', subnet.cidr_block,
        'AZ', subnet.availability_zone,
        'Account ID', subnet.account_id,
        'Region', subnet.region
      ) as properties
    from
      aws_ec2_instance as i,
      aws_vpc_subnet as subnet
    where
      i.arn = $1
      and i.subnet_id = subnet.subnet_id;
  EOQ

  param "arn" {}
}

# edge "aws_ec2_instance_to_vpc_subnet_edge" {
#   title = "subnet"

#   sql = <<-EOQ
#     select
#       coalesce(
#         eni.network_interface_id,
#         i.instance_id
#       ) as from_id,
#       i.subnet_id as to_id
#     from
#       aws_ec2_instance as i
#       left join aws_ec2_network_interface as eni on i.instance_id = eni.attached_instance_id
#     where
#       arn = $1
#   EOQ

#   param "arn" {}
# }



edge "aws_ec2_instance_to_vpc_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      sg ->> 'GroupId' as from_id,
      i.subnet_id as to_id
    from
      aws_ec2_instance as i
      join jsonb_array_elements(security_groups) as sg on true

  where
      arn = $1
  EOQ

  param "arn" {}
}

node "aws_ec2_instance_vpc_subnet_to_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      vpc.vpc_id as id,
      vpc.title as title,
      jsonb_build_object(
        'ID', vpc.vpc_id,
        'Name', vpc.tags ->> 'Name',
        'CIDR Block', vpc.cidr_block,
        'Account ID', vpc.account_id,
        'Owner ID', vpc.owner_id,
        'Region', vpc.region
      ) as properties
    from
      aws_ec2_instance as i,
      aws_vpc as vpc
    where
      i.arn = $1
      and i.vpc_id = vpc.vpc_id;
  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_vpc_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      vpc_id as to_id
    from
      aws_ec2_instance as i
    where
      subnet_id is not null
      and vpc_id is not null
      and arn = $1
  EOQ

  param "arn" {}
}

node "aws_ec2_instance_to_iam_profile_node" {
  category = category.aws_iam_profile

  sql = <<-EOQ
    select
      iam_instance_profile_arn as id,
      split_part(iam_instance_profile_arn, ':instance-profile/',2) as title,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn,
        'Instance Profile ID', iam_instance_profile_id
      ) as properties
    from
      aws_ec2_instance as i
    where
      iam_instance_profile_arn is not null
      and i.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_to_iam_profile_edge" {
  title = "runs as"

  sql = <<-EOQ
    select
      instance_id as from_id,
      iam_instance_profile_arn as to_id
    from
      aws_ec2_instance as i
    where
      iam_instance_profile_arn is not null
      and i.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_ec2_instance_to_iam_role_node" {
  category = category.aws_iam_role

  sql = <<-EOQ
    select
      r.arn as id,
      r.title as title,
      jsonb_build_object(
        'Name', r.name,
        'Description', r.description,
        'ARN', r.arn ,
        'Account ID', r.account_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      instance_profile = i.iam_instance_profile_arn
      and i.arn = $1

  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_to_iam_role_edge" {
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

  param "arn" {}
}

node "aws_ec2_instance_to_ec2_key_pair_node" {
  category = category.aws_ec2_key_pair

  sql = <<-EOQ
    select
      k.key_name as id,
      k.title as title,
      jsonb_build_object(
        'Name', k.key_name,
        'ID', k.key_pair_id,
        'Fingerprint', key_fingerprint
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ec2_key_pair as k
    where
      i.key_name = k.key_name
      and i.account_id = k.account_id
      and i.region = k.region
      and i.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_to_ec2_key_pair_edge" {
  title = "key pair"

  sql = <<-EOQ
    select
      instance_id as from_id,
      key_name as to_id
    from
      aws_ec2_instance as i
    where
      key_name is not null
      and i.arn = $1;
  EOQ

  param "arn" {}
}

/* node "aws_ec2_instance_to_ec2_ami_node" {
  category = category.aws_ec2_ami

  sql = <<-EOQ
    select
      ami.image_id as id,
      ami.name as title,
      jsonb_build_object(
        'Image ID', ami.image_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ec2_ami_shared as ami
    where
      ami.image_id = i.image_id
      and i.arn = 'arn:aws:ec2:eu-west-1:533793682495:instance/i-079fe88a8a1cf793d';
  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_to_ec2_ami_edge" {
  title = "launched with"

  sql = <<-EOQ
    select
      instance_id as from_id,
      image_id as to_id,
      jsonb_build_object(
        'Account ID', i.account_id,
        'Image ID', image_id,
        'Instance ID', instance_id
      ) as properties
    from
      aws_ec2_instance as i
    where
      i.arn = 'arn:aws:ec2:eu-west-1:533793682495:instance/i-079fe88a8a1cf793d';
  EOQ

  param "arn" {}
} */

node "aws_ec2_instance_from_ec2_autoscaling_group_node" {
  category = category.aws_ec2_autoscaling_group

  sql = <<-EOQ
    select
      k.autoscaling_group_arn as id,
      k.name as title,
      jsonb_build_object(
        'instance', group_instance ->> 'InstanceId',
        'i', i.instance_id,
        'asg', group_instance
      ) as properties
    from
      aws_ec2_autoscaling_group as k,
      jsonb_array_elements(k.instances) as group_instance,
      aws_ec2_instance as i
    where
      i.arn = $1
      and group_instance ->> 'InstanceId' = i.instance_id;
  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_from_ec2_autoscaling_group_edge" {
  title = "launches"

  sql = <<-EOQ
    select
      k.autoscaling_group_arn as from_id,
      i.instance_id as to_id
    from
      aws_ec2_autoscaling_group as k,
      jsonb_array_elements(k.instances) as group_instance,
      aws_ec2_instance as i
    where
      i.arn = $1
      and group_instance ->> 'InstanceId' = i.instance_id;
  EOQ

  param "arn" {}
}

node "aws_ec2_instance_from_ec2_classic_load_balancer_node" {
  category = category.aws_ec2_classic_load_balancer

  sql = <<-EOQ
    select
      k.arn as id,
      k.name as title,
      jsonb_build_object(
        'instance', group_instance ->> 'InstanceId',
        'i', i.instance_id,
        'clb', group_instance
      ) as properties
    from
      aws_ec2_classic_load_balancer as k,
      jsonb_array_elements(k.instances) as group_instance,
      aws_ec2_instance as i
    where
      i.arn = $1
      and group_instance ->> 'InstanceId' = i.instance_id;
  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_from_ec2_classic_load_balancer_edge" {
  title = "routes to"

  sql = <<-EOQ
    select
      k.arn as from_id,
      i.instance_id as to_id
    from
      aws_ec2_classic_load_balancer as k,
      jsonb_array_elements(k.instances) as group_instance,
      aws_ec2_instance as i
    where
      i.arn = $1
      and group_instance ->> 'InstanceId' = i.instance_id;
  EOQ

  param "arn" {}
}

node "aws_ec2_instance_from_ec2_target_group_node" {
  category = category.aws_ec2_target_group

  sql = <<-EOQ
    select
      target.target_group_arn as id,
      target.target_group_name as title,
      jsonb_build_object(
        'Name', target.target_group_name,
        'ARN', target.target_group_arn,
        'Health Check Enabled', target.health_check_enabled,
        'Region', target.region,
        'Account ID', target.account_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions
    where
      i.arn = $1
      and health_descriptions -> 'Target' ->> 'Id' = i.instance_id
  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_from_ec2_target_group_edge" {
  title = "routes to"

  sql = <<-EOQ
    select
      target.target_group_arn as from_id,
      i.instance_id as to_id
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions
    where
      i.arn = $1
      and health_descriptions -> 'Target' ->> 'Id' = i.instance_id;
  EOQ

  param "arn" {}
}




node "aws_ec2_instance_from_ec2_alb_node" {
  category = category.aws_ec2_application_load_balancer

  sql = <<-EOQ
    select
      distinct on (lb.arn)
      lb.arn as id,
      lb.name as title,
      jsonb_build_object(
        'Name', lb.name,
        'ARN', lb.arn,
        'Region', lb.region,
        'Account ID', lb.account_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
      jsonb_array_elements_text(target.load_balancer_arns) as l,
      aws_ec2_application_load_balancer as lb
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id
      and l = lb.arn
      and i.arn = $1

  EOQ

  param "arn" {}
}


node "aws_ec2_instance_from_ec2_nlb_node" {
  category = category.aws_ec2_network_load_balancer

  sql = <<-EOQ
    select
      distinct on (lb.arn)
      lb.arn as id,
      lb.name as title,
      jsonb_build_object(
        'Name', lb.name,
        'ARN', lb.arn,
        'Region', lb.region,
        'Account ID', lb.account_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
      jsonb_array_elements_text(target.load_balancer_arns) as l,
      aws_ec2_network_load_balancer as lb
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id
      and l = lb.arn
      and i.arn = $1

  EOQ

  param "arn" {}
}


node "aws_ec2_instance_from_ec2_gwlb_node" {
  category = category.aws_ec2_gateway_load_balancer

  sql = <<-EOQ
    select
      distinct on (lb.arn)
      lb.arn as id,
      lb.name as title,
      jsonb_build_object(
        'Name', lb.name,
        'ARN', lb.arn,
        'Region', lb.region,
        'Account ID', lb.account_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
      jsonb_array_elements_text(target.load_balancer_arns) as l,
      aws_ec2_gateway_load_balancer as lb
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id
      and l = lb.arn
      and i.arn = $1

  EOQ

  param "arn" {}
}


edge "aws_ec2_instance_lb_target_group_edge" {
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
      and i.arn = $1
  EOQ

  param "arn" {}
}


node "aws_ec2_instance_ecs_cluster_node" {
  category = category.aws_ecs_cluster

  sql = <<-EOQ
    select
      cluster.cluster_arn as id,
      cluster.cluster_name as title,
      jsonb_build_object(
        'Name', cluster.cluster_name,
        'ARN', cluster.cluster_arn,
        'Region', cluster.region,
        'Account ID', cluster.account_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ecs_container_instance as ci,
      aws_ecs_cluster as cluster
    where
      ci.ec2_instance_id = i.instance_id
      and ci.cluster_arn = cluster.cluster_arn
      and i.arn = $1

  EOQ

  param "arn" {}
}




edge "aws_ec2_instance_from_cluster_edge" {
  title = "container instance"

  sql = <<-EOQ
    select
      cluster.cluster_arn as from_id,
      i.instance_id as to_id
    from
      aws_ec2_instance as i,
      aws_ecs_container_instance as ci,
      aws_ecs_cluster as cluster
    where
      ci.ec2_instance_id = i.instance_id
      and ci.cluster_arn = cluster.cluster_arn
      and i.arn = $1
  EOQ

  param "arn" {}
}
//***********


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
      p ->> 'GroupName' as "Group Name"
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
      ips -> 'Association' ->> 'PublicIp' as "Public IP Address",
      ips ->> 'PrivateIpAddress' as "Private IP Address",
      p ->> 'Status' as "Status",
      p ->> 'SubnetId' as "Subnet ID",
      p ->> 'VpcId' as "VPC ID"
    from
      aws_ec2_instance,
      jsonb_array_elements(network_interfaces) as p,
      jsonb_array_elements(p -> 'PrivateIpAddresses') as ips
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
